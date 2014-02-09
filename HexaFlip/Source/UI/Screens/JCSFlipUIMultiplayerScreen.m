//
//  JCSFlipUIMultiplayerScreen.m
//  HexaFlip
//
//  Created by Christian Schuster on 15.01.13.
//  Copyright (c) 2013 Christian Schuster. All rights reserved.
//

#import <GameKit/GameKit.h>

#import "JCSFlipUIMultiplayerScreen.h"
#import "JCSFlipGameState.h"
#import "JCSFlipPlayerLocal.h"
#import "JCSFlipPlayerGameCenter.h"
#import "JCSFlipGameCenterManager.h"
#import "JCSFlipUIEvents.h"

@implementation JCSFlipUIMultiplayerScreen {
    GKTurnBasedMatchmakerViewController *_mmvc;
}

- (void)didActivateScreen {
    GKMatchRequest *matchRequest = [[GKMatchRequest alloc] init];
    matchRequest.minPlayers = 2;
    matchRequest.maxPlayers = 2;
    matchRequest.playersToInvite = _playersToInvite;
    
    _mmvc = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:matchRequest];
    _mmvc.turnBasedMatchmakerDelegate = self;
    // don't show existing matches when inviting
    _mmvc.showExistingMatches = (_playersToInvite == nil);
    [[CCDirector sharedDirector] presentViewController:_mmvc animated:YES completion:nil];
}

- (void)willDeactivateScreen {
    [self dismissWithCompletion:nil];
}

- (void)dismissWithCompletion:(void(^)())completion {
    GKTurnBasedMatchmakerViewController *mmvc = _mmvc;
    _mmvc = nil;
    [mmvc dismissViewControllerAnimated:YES completion:completion];
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate methods

// The user has cancelled
- (void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // dismiss and post notification
    [self dismissWithCompletion:^{
        [nc postNotificationName:JCS_FLIP_UI_CANCEL_EVENT_NAME object:self];
    }];
}

// Matchmaking has failed with an error
- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    // prepare the notification data
    JCSFlipUIErrorEventData *data = [[JCSFlipUIErrorEventData alloc] initWithError:error];
    
    // post notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [self dismissWithCompletion:^{
        [nc postNotificationName:JCS_FLIP_UI_CANCEL_EVENT_NAME object:self eventData:data];
    }];
}

// A turned-based match has been found, the game should start
- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match {
    // extract the game state from the match, or create a new one
    JCSFlipGameCenterManager *gameCenterManager = [JCSFlipGameCenterManager sharedInstance];
    JCSFlipGameState *gameState = [gameCenterManager buildGameStateFromMatch:match];
    
    // determine playerId of local participant
    NSString *localPlayerId = [gameCenterManager localPlayerID];
    
    // determine if player A is local
    GKTurnBasedParticipant *participantA = match.participants[0];
    BOOL playerAIsLocal = [localPlayerId isEqualToString:participantA.playerID];
    
    // determine if it's player A's turn
    BOOL playerAIsToMove = (gameState.playerToMove == JCSFlipPlayerSideA);
    
    // determine if the last move has been taken by the remote player
    BOOL lastMoveByRemotePlayer = (playerAIsToMove == playerAIsLocal);
    
    // initialize the players
    id<JCSFlipPlayer> localPlayer = [JCSFlipPlayerLocal player];
    id<JCSFlipPlayer> remotePlayer = [JCSFlipPlayerGameCenter player];
    id<JCSFlipPlayer> playerA = playerAIsLocal ? localPlayer : remotePlayer;
    id<JCSFlipPlayer> playerB = playerAIsLocal ? remotePlayer : localPlayer;
    
    // check if match is open (i.e. has not ended yet)
    BOOL matchOpen = (match.status == GKTurnBasedMatchStatusOpen);
    
    // prepare the notification data
    // animate the last move only if it has been taken by the remote player
    // disable move input if match is not open
    JCSFlipUIPrepareGameEventData *data = [[JCSFlipUIPrepareGameEventData alloc] initWithGameState:gameState playerA:playerA playerB:playerB match:match animateLastMove:lastMoveByRemotePlayer moveInputDisabled:!matchOpen];
    
    // prepare the game, and start it after dismissing the controller
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:JCS_FLIP_UI_PREPARE_GAME_EVENT_NAME object:self eventData:data];
    [self dismissWithCompletion:^{
        [nc postNotificationName:JCS_FLIP_UI_PLAY_GAME_EVENT_NAME object:self];
    }];
}

// Called when a users chooses to quit a match and that player has the current turn.  The developer should call playerQuitInTurnWithOutcome:nextPlayer:matchData:completionHandler: on the match passing in appropriate values.  They can also update matchOutcome for other players as appropriate.
- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match {
    // determine next participant
    NSUInteger currentParticipantIndex = [match.participants indexOfObject:match.currentParticipant];
    NSUInteger nextParticipantIndex = 1-currentParticipantIndex;
    GKTurnBasedParticipant *nextParticipant = match.participants[nextParticipantIndex];
    
    // if the participant quits in turn, the other participant wins
    match.currentParticipant.matchOutcome = GKTurnBasedMatchOutcomeQuit;
    nextParticipant.matchOutcome = GKTurnBasedMatchOutcomeWon;
    
    // extract the match data
    JCSFlipGameState *gameState = [[JCSFlipGameCenterManager sharedInstance] buildGameStateFromMatch:match];
    
    // build the match data to send
    NSData *data = [[JCSFlipGameCenterManager sharedInstance] buildDataFromGameState:gameState];
    
    // end the match
    [match endMatchInTurnWithMatchData:data completionHandler:nil];
}

- (BOOL)leaveScreenWhenPlayerLoggedOut {
    return YES;
}

@end
