//
//  JCSFlipUIGameScreen.h
//  HexaFlip
//
//  Created by Christian Schuster on 03.11.12.
//  Copyright (c) 2012 Christian Schuster. All rights reserved.
//

#import <GameKit/GameKit.h>

#import "JCSFlipPlayerMoveInputDelegate.h"
#import "JCSFlipUIScreenWithPoint.h"

#import "cocos2d.h"

@class JCSFlipGameState;
@protocol JCSFlipPlayer;
@protocol JCSFlipUIGameScreenDelegate;

@interface JCSFlipUIGameScreen : CCNode <JCSFlipPlayerMoveInputDelegate, JCSFlipUIScreenWithPoint>

// the screen delegate
@property (weak, nonatomic) id<JCSFlipUIGameScreenDelegate> delegate;

// prepare a game with the given state, players, and game center match
// set the receiver as the move input delegate of both players
// the players might be both nil to show a read-only game
// the match might be nil for local games
- (void)prepareGameWithState:(JCSFlipGameState *)state playerA:(id<JCSFlipPlayer>)playerA playerB:(id<JCSFlipPlayer>)playerB match:(GKTurnBasedMatch *)match;

// start a previously prepared game
// the screen must be enabled when this method is invoked
- (void)startGame;

@end
