import '../../domain/models/enums.dart';
import '../../domain/models/urge_log.dart';

class CopingPromptService {
  CopingPrompt promptForUrge({
    UrgeTrigger? trigger,
    UrgeMood? mood,
    bool riskyMoment = false,
  }) {
    if (riskyMoment) {
      return const CopingPrompt(
        title: 'Risky moment detected',
        message:
            'This is a time you have struggled before. Pause for 10 minutes and '
            'the urge will pass. Text a friend or leave the situation.',
        technique: 'Urge surfing',
      );
    }

    switch (trigger) {
      case UrgeTrigger.payday:
        return const CopingPrompt(
          title: 'Payday pause',
          message:
              'Move money to a savings account now, or enable bank gambling blocks. '
              'Payday urges fade once cash is out of reach.',
          technique: 'Remove access',
        );
      case UrgeTrigger.nearVenue:
        return const CopingPrompt(
          title: 'Walk away',
          message:
              'Change your route. Physical distance breaks the loop. '
              'Call someone from your support circle.',
          technique: 'Change environment',
        );
      case UrgeTrigger.chasingLosses:
        return const CopingPrompt(
          title: 'Stop the chase',
          message:
              'Chasing losses makes things worse and that is the addiction talking. '
              'The money is gone; protecting what is left is the win.',
          technique: 'Cognitive reframe',
        );
      case UrgeTrigger.aloneAtHome:
        return const CopingPrompt(
          title: 'Break the isolation',
          message:
              'Loneliness fuels urges. Message a friend, go for a walk, '
              'or do something with your hands for 15 minutes.',
          technique: 'Social connection',
        );
      case UrgeTrigger.afterDrink:
        return const CopingPrompt(
          title: 'Alcohol lowers guard',
          message:
              'Put your card away and enable spending delays. '
              'Decisions made now are not your best ones.',
          technique: 'Delay + block',
        );
      default:
        break;
    }

    switch (mood) {
      case UrgeMood.stressed:
        return const CopingPrompt(
          title: 'Stress urge',
          message:
              'Gambling will not fix the stress and it will add debt. '
              'Try 4-7-8 breathing: inhale 4s, hold 7s, exhale 8s.',
          technique: 'Breathing',
        );
      case UrgeMood.bored:
        return const CopingPrompt(
          title: 'Boredom urge',
          message:
              'Boredom is temporary. Pick one small task and finish it before '
              'you decide anything about gambling.',
          technique: 'Behavioural activation',
        );
      case UrgeMood.lonely:
        return const CopingPrompt(
          title: 'Lonely urge',
          message:
              'Reach out to one person right now because even a short message counts. '
              'Connection beats isolation every time.',
          technique: 'Social connection',
        );
      default:
        return const CopingPrompt(
          title: 'Ride the wave',
          message:
              'Urges peak and pass in 15–20 minutes. You do not have to act on this. '
              'Log it, breathe, and wait.',
          technique: 'Urge surfing',
        );
    }
  }

  CopingPrompt promptForBlocksIncomplete(int blocksActive, int blocksTotal) {
    if (blocksActive >= blocksTotal) {
      return const CopingPrompt(
        title: 'Barriers in place',
        message: 'Your access blocks are active. Use them because that is the point.',
        technique: 'Harm reduction',
      );
    }
    return CopingPrompt(
      title: 'Strengthen your barriers',
      message:
          'You have $blocksActive of $blocksTotal blocks set up. '
          'GAMSTOP + bank blocks stop gambling in the moment better than willpower alone.',
      technique: 'Remove access',
    );
  }
}
