import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const COOLDOWN_MS = 15 * 60 * 1000;

interface BreachEvent {
  userId: string;
  commitmentId: string;
  groupId: string;
  signalType: string;
  metadata: Record<string, unknown>;
  severity: string;
  userName?: string;
}

interface SupportMessage {
  breachEventId: string;
  fromUserId: string;
  toUserId: string;
  message: string;
  type: string;
  fromUserName?: string;
}

function buildBreachSummary(signalType: string, metadata: Record<string, unknown>): string {
  switch (signalType) {
    case "location":
      return `Near ${metadata.placeName ?? "a gambling location"}`;
    case "app":
      return `Opened ${metadata.appName ?? "gambling app"}`;
    case "url":
      return `Visited ${metadata.url ?? "gambling website"}`;
    case "payment":
      return "Possible gambling spend detected";
    default:
      return "May need support";
  }
}

async function getGroupMemberTokens(
  groupId: string,
  excludeUserId: string
): Promise<{ uid: string; token: string }[]> {
  const groupDoc = await db.collection("groups").doc(groupId).get();
  if (!groupDoc.exists) return [];

  const memberIds: string[] = groupDoc.data()?.memberIds ?? [];
  const tokens: { uid: string; token: string }[] = [];

  for (const memberId of memberIds) {
    if (memberId === excludeUserId) continue;
    const userDoc = await db.collection("users").doc(memberId).get();
    const token = userDoc.data()?.fcmToken as string | undefined;
    if (token) tokens.push({ uid: memberId, token });
  }

  return tokens;
}

async function sendMulticastWithCleanup(
  tokens: { uid: string; token: string }[],
  payload: admin.messaging.MulticastMessage
): Promise<void> {
  if (tokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    ...payload,
    tokens: tokens.map((t) => t.token),
  });

  response.responses.forEach(async (res, index) => {
    if (!res.success) {
      const code = res.error?.code;
      if (
        code === "messaging/invalid-registration-token" ||
        code === "messaging/registration-token-not-registered"
      ) {
        const uid = tokens[index].uid;
        console.log(`Removing invalid FCM token for user ${uid}`);
        await db.collection("users").doc(uid).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      } else {
        console.error(`FCM error for token index ${index}:`, res.error?.message);
      }
    }
  });
}

export const onBreachCreated = onDocumentCreated(
  "breach_events/{eventId}",
  async (event) => {
    const data = event.data?.data() as BreachEvent | undefined;
    if (!data) return;

    const eventId = event.params.eventId;
    const { userId, groupId, signalType, metadata, userName } = data;

    const recent = await db
      .collection("breach_events")
      .where("userId", "==", userId)
      .where("signalType", "==", signalType)
      .orderBy("createdAt", "desc")
      .limit(2)
      .get();

    if (recent.docs.length > 1) {
      const previous = recent.docs[1];
      const prevTime = previous.data().createdAt?.toMillis?.() ?? 0;
      const currentTime = event.data?.createTime?.toMillis?.() ?? Date.now();
      if (currentTime - prevTime < COOLDOWN_MS) {
        console.log(`Skipping duplicate breach ${eventId}`);
        return;
      }
    }

    const tokens = await getGroupMemberTokens(groupId, userId);
    if (tokens.length === 0) {
      console.log("No FCM tokens for group members");
      return;
    }

    const summary = buildBreachSummary(signalType, metadata ?? {});

    await sendMulticastWithCleanup(tokens, {
      tokens: tokens.map((t) => t.token),
      notification: {
        title: `${userName ?? "Friend"} may need support`,
        body: summary,
      },
      data: {
        type: "breach_alert",
        eventId,
        userName: userName ?? "Friend",
        signalType,
        summary,
        groupId,
      },
    });

    console.log(`Sent breach alert for ${eventId} to ${tokens.length} friends`);
  }
);

export const onSupportCreated = onDocumentCreated(
  "support_messages/{messageId}",
  async (event) => {
    const data = event.data?.data() as SupportMessage | undefined;
    if (!data) return;

    const { toUserId, message, fromUserName } = data;

    const userDoc = await db.collection("users").doc(toUserId).get();
    const token = userDoc.data()?.fcmToken as string | undefined;
    if (!token) return;

    try {
      await messaging.send({
        token,
        notification: {
          title: `${fromUserName ?? "A friend"} sent support`,
          body: message,
        },
        data: {
          type: "support_received",
          fromName: fromUserName ?? "A friend",
          message,
        },
      });
    } catch (error: unknown) {
      const err = error as { code?: string };
      if (
        err.code === "messaging/invalid-registration-token" ||
        err.code === "messaging/registration-token-not-registered"
      ) {
        await db.collection("users").doc(toUserId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }
      console.error("Support notification failed:", error);
    }
  }
);
