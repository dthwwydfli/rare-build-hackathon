"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onSupportCreated = exports.onBreachCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const COOLDOWN_MS = 15 * 60 * 1000;
function buildBreachSummary(signalType, metadata) {
    var _a, _b, _c, _d;
    switch (signalType) {
        case "location":
            return `Near ${(_a = metadata.placeName) !== null && _a !== void 0 ? _a : "a gambling location"}`;
        case "app":
            return `Opened ${(_b = metadata.appName) !== null && _b !== void 0 ? _b : "gambling app"}`;
        case "url":
            return `Visited ${(_c = metadata.url) !== null && _c !== void 0 ? _c : "gambling website"}`;
        case "payment":
            return "Possible gambling spend detected";
        case "manual":
            return metadata.selfFlagged
                ? "Asked their circle for support"
                : ((_d = metadata.note) !== null && _d !== void 0 ? _d : "May need support");
        default:
            return "May need support";
    }
}
async function getGroupMemberTokens(groupId, excludeUserId) {
    var _a, _b, _c;
    const groupDoc = await db.collection("groups").doc(groupId).get();
    if (!groupDoc.exists)
        return [];
    const memberIds = (_b = (_a = groupDoc.data()) === null || _a === void 0 ? void 0 : _a.memberIds) !== null && _b !== void 0 ? _b : [];
    const tokens = [];
    for (const memberId of memberIds) {
        if (memberId === excludeUserId)
            continue;
        const userDoc = await db.collection("users").doc(memberId).get();
        const token = (_c = userDoc.data()) === null || _c === void 0 ? void 0 : _c.fcmToken;
        if (token)
            tokens.push({ uid: memberId, token });
    }
    return tokens;
}
async function sendMulticastWithCleanup(tokens, payload) {
    if (tokens.length === 0)
        return;
    const response = await messaging.sendEachForMulticast({
        ...payload,
        tokens: tokens.map((t) => t.token),
    });
    response.responses.forEach(async (res, index) => {
        var _a, _b;
        if (!res.success) {
            const code = (_a = res.error) === null || _a === void 0 ? void 0 : _a.code;
            if (code === "messaging/invalid-registration-token" ||
                code === "messaging/registration-token-not-registered") {
                const uid = tokens[index].uid;
                console.log(`Removing invalid FCM token for user ${uid}`);
                await db.collection("users").doc(uid).update({
                    fcmToken: admin.firestore.FieldValue.delete(),
                });
            }
            else {
                console.error(`FCM error for token index ${index}:`, (_b = res.error) === null || _b === void 0 ? void 0 : _b.message);
            }
        }
    });
}
exports.onBreachCreated = (0, firestore_1.onDocumentCreated)("breach_events/{eventId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
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
        const prevTime = (_d = (_c = (_b = previous.data().createdAt) === null || _b === void 0 ? void 0 : _b.toMillis) === null || _c === void 0 ? void 0 : _c.call(_b)) !== null && _d !== void 0 ? _d : 0;
        const currentTime = (_h = (_g = (_f = (_e = event.data) === null || _e === void 0 ? void 0 : _e.createTime) === null || _f === void 0 ? void 0 : _f.toMillis) === null || _g === void 0 ? void 0 : _g.call(_f)) !== null && _h !== void 0 ? _h : Date.now();
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
    const summary = buildBreachSummary(signalType, metadata !== null && metadata !== void 0 ? metadata : {});
    await sendMulticastWithCleanup(tokens, {
        tokens: tokens.map((t) => t.token),
        notification: {
            title: `${userName !== null && userName !== void 0 ? userName : "Friend"} may need support`,
            body: summary,
        },
        data: {
            type: "breach_alert",
            eventId,
            userName: userName !== null && userName !== void 0 ? userName : "Friend",
            signalType,
            summary,
            groupId,
        },
    });
    console.log(`Sent breach alert for ${eventId} to ${tokens.length} friends`);
});
exports.onSupportCreated = (0, firestore_1.onDocumentCreated)("support_messages/{messageId}", async (event) => {
    var _a, _b;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const { toUserId, message, fromUserName } = data;
    const userDoc = await db.collection("users").doc(toUserId).get();
    const token = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
    if (!token)
        return;
    try {
        await messaging.send({
            token,
            notification: {
                title: `${fromUserName !== null && fromUserName !== void 0 ? fromUserName : "A friend"} sent support`,
                body: message,
            },
            data: {
                type: "support_received",
                fromName: fromUserName !== null && fromUserName !== void 0 ? fromUserName : "A friend",
                message,
            },
        });
    }
    catch (error) {
        const err = error;
        if (err.code === "messaging/invalid-registration-token" ||
            err.code === "messaging/registration-token-not-registered") {
            await db.collection("users").doc(toUserId).update({
                fcmToken: admin.firestore.FieldValue.delete(),
            });
        }
        console.error("Support notification failed:", error);
    }
});
//# sourceMappingURL=index.js.map