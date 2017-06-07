-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 7 : Senatorial Voting Procedure
 * To provide an orderly democratic process within the Imperial Senate, the
 * Imperitor of the Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Definition of Ballots and Ballot Choices" ,
"To settle many impotant matters, votes shall be cast, in which citizens shall
select their choices from [ballots][1]. A ballot is a set of [choices][2] on
which the citizens may vote.

  [1]: OBJECT::[Senate].[Ballots]
  [2]: OBJECT::[Senate].[BallotChoices]" ,
"CREATE TABLE [Senate].[Ballots](
  [Id] int NOT NULL
           IDENTITY( 1 , 1 )
           PRIMARY KEY );
CREATE TABLE [Senate].[BallotChoices](
  [BallotId] int NOT NULL ,
  [Value] tinyint NOT NULL ,
  [Name] sysname ,
  PRIMARY KEY ( [BallotId] , [Value] ) ,
  UNIQUE ( [BallotId] , [Name] ) ,
  FOREIGN KEY ( [BallotId] ) REFERENCES [Senate].[Ballots]( [Id] ));" ) ,
    ( "Definition of Elections" ,
"Votes shall be cast in [elections][1], which specify the rules under which
votes are to be cast, including a reference to the ballot that shall be used
for that election, whether the election is a public election, and the period
of time during which votes may be cast.

  [1]: OBJECT::[Senate].[Elections]" ,
"CREATE TABLE [Senate].[Elections](
  [Id] bigint NOT NULL
              IDENTITY ( 1, 1 )
              PRIMARY KEY ,
  [BallotId] int NOT NULL ,
  [IsPublic] bit NOT NULL ,
  [OpenedOn] datetime NOT NULL ,
  [ClosedOn] datetime NOT NULL ,
  [OpenEventRaised] bit NOT NULL
                        DEFAULT( 0 ) ,
  [CloseEventRaised] bit NOT NULL
                         DEFAULT( 0 ) ,
  UNIQUE ( [Id], [BallotId] ) ,
  FOREIGN KEY ( [BallotId] ) REFERENCES [Senate].[Ballots]( [Id] ));
CREATE NONCLUSTERED INDEX [IX_Elections_OpenedOn]
  ON [Senate].[Elections] ( [OpenedOn] );
CREATE NONCLUSTERED INDEX [IX_Elections_ClosedOn]
  ON [Senate].[Elections] ( [ClosedOn] );" ),
    ( "Definition of Votes" ,
"Each [vote][1] cast in an election shall note the election in which the
vote was cast, name of the voter that cast the vote, and the choice selected
by the voter.

  [1]: OBJECT::[Senate].[Votes]" ,
"CREATE TABLE [Senate].[Votes](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [ElectionId] bigint NOT NULL ,
  [BallotId] int NOT NULL ,
  [Value] tinyint NOT NULL ,
  [CastOn] datetime NOT NULL
                    DEFAULT( GETUTCDATE() ) ,
  [CastBy] int NOT NULL
               DEFAULT( USER_ID() ) ,
  FOREIGN KEY ( [ElectionId] , [BallotId] )
    REFERENCES [Senate].[Elections]( [Id] , [BallotId] ) ,
  FOREIGN KEY ( [BallotId] )
    REFERENCES [Senate].[Ballots]( [Id] ) ,
  FOREIGN KEY ( [BallotId] , [Value] )
    REFERENCES [Senate].[BallotChoices] ( [BallotId] , [Value] ) ,
  UNIQUE ( [ElectionId] , [CastBy] ));" ) ,
    ( "Definition of Public Votes" ,
"A [public vote][1] is a vote cast in a public elections.

  [1]: OBJECT::[Senate].[PublicVotes]" ,
"CREATE VIEW [Senate].[PublicVotes]
AS
SELECT
    v.[Id] ,
    v.[ElectionId] ,
    v.[BallotId] ,
    v.[Value] ,
    v.[CastOn] ,
    v.[CastBy]
  FROM [Senate].[Votes] AS v
  JOIN [Senate].[Elections] AS e
    ON e.[Id] = v.[ElectionId]
  WHERE e.[IsPublic] = 1;" ) ,
    ( "Definition of Open Elections" ,
"An [open election][1] is an election that was opened prior to or on the
current date and time and that will close after the current date and time.

  [1]: OBJECT::[Senate].[OpenElections]" ,
"CREATE VIEW [Senate].[OpenElections]
AS
SELECT
    [Id] ,
    [BallotId] ,
    [IsPublic] ,
    [OpenedOn] ,
    [ClosedOn] ,
    [OpenEventRaised] ,
    [CloseEventRaised]
  FROM [Senate].[Elections]
  WHERE [OpenedOn] <= GETUTCDATE() AND
        [ClosedOn] > GETUTCDATE();" ) ,
    ( "Definition of Closed Elections" ,
"An [closed election][1] is an election that was closed prior to or on the
current date and time.

  [1]: OBJECT::[Senate].[ClosedElections]" ,
"CREATE VIEW [Senate].[ClosedElections]
AS
SELECT
    [Id] ,
    [BallotId] ,
    [IsPublic] ,
    [OpenedOn] ,
    [ClosedOn] ,
    [OpenEventRaised] ,
    [CloseEventRaised]
  FROM [Senate].[Elections]
  WHERE [ClosedOn] <= GETUTCDATE();" ) ,
    ( "Ancillary Action Log Regarding Votes Cast in the Senate (I)" ,
"The [action log][1] shall include [ancillary information][2] regarding
[votes][3] cast in the [senate][4].

  [1]: OBJECT::[Action].[Log]
  [2]: OBJECT::[Action].[ActionLogVotes]
  [3]: OBJECT::[Senate].[Bills]
  [4]: SCHEMA::[Senate]" ,
"CREATE TABLE [Action].[ActionLogVotes](
  [LogId] bigint NOT NULL ,
  [VoteId] bigint NOT NULL ,
  FOREIGN KEY ( [LogId] ) REFERENCES [Action].[ActionLog]( [Id] ) ,
  FOREIGN KEY ( [VoteId] ) REFERENCES [Senate].[Votes]( [Id] ) );" ) ,
    ( "Ancillary Action Log Regarding Votes Cast in the Senate (II)" ,
"[Ancillary information][1] in a person's [action log][2] regarding votes cast
in the senate shall be a [component][3] of that person's [personal
profile][4].

  [1]: OBJECT::[Action].[ActionLogVotes]
  [2]: OBJECT::[Action].[ActionLog]
  [3]: OBJECT::[My].[ActionLogVotes]
  [4]: SCHEMA::[My]" ,
"CREATE VIEW [My].[ActionLogVotes]
AS
SELECT
    x.[LogId] ,
    x.[VoteId]
  FROM [Action].[ActionLogVotes] x
  JOIN [Action].[ActionLog] y ON x.[LogId] = y.[Id];" ) ,
    ( "Ancillary Action Log Regarding Votes Cast in the Senate (III)" ,
"Recording [ancillary information][1] in the [action log][2] regarding votes
cast in the senate is done by noting the ID of the bill in the action log.

  [1]: OBJECT::[Action].[RecordActionLogVotes]
  [2]: OBJECT::[My].[ActionLog]
  [3]: SCHEMA::[My]" ,
"CREATE PROCEDURE [Action].[RecordActionLogVotes]
  @LogId bigint ,
  @VoteId bigint
AS
BEGIN
  IF @LogId IS NULL OR @VoteId IS NULL
    THROW 50000 , 'All parameters must be non-null.' , 1;
  ELSE
    INSERT [Action].[ActionLogVotes]( [LogId] , [VoteId] )
      VALUES( @LogId , @VoteId );
END" ) ,
    ( "Voting Procedure" ,
"To [cast a vote][1] in the senate in a given election and with given choice
selected is to perform the following procedure:

  1. if said election is not open, raise an error and stop
  2. if said choice does not appear on the ballot of said election, raise an
     error and stop
  3. if the voter has already cast a vote in said election, raise an error
     and stop
  4. evaluate the simple action point requirement associated with this
     process
  5. record the vote
  6. record ancillary information in the activity log regarding this process

  [1]: OBJECT::[Senate].[Vote]" ,
"CREATE PROCEDURE [Senate].[Vote]
  @electionId bigint ,
  @choice sysname ,
  @voteId bigint = NULL OUTPUT
  WITH EXECUTE AS CALLER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @castOn datetime = GETUTCDATE() ,
          @castBy int ,
          @curVote bigint ,
          @ballotId int ,
          @value tinyint ,
          @logId bigint ,
          @err nvarchar(100) ,
          @open bit ,
          @result int = -1;

  SELECT
      @castBy = USER_ID() ,
      @open = 1 ,
      @ballotId = [BallotId]
    FROM [Senate].[OpenElections]
    WHERE [Id] = @electionId;
  SET @err =
    CASE
      WHEN @choice IS NULL THEN 'Parameter @choice must not be null.'
      WHEN @electionId IS NULL THEN 'Parameter @electionId must not be null.'
      WHEN @open IS NULL THEN 'The specified election is not open.'
    END;
  IF @err IS NOT NULL
    THROW 50000 , @err , 1;
  ELSE

  SELECT @curVote = [Id]
    FROM [Senate].[Votes]
    WHERE [ElectionId] = @electionId
      AND [CastBy] = @castBy
    ORDER BY [Id] DESC;
  SELECT @value = [Value]
    FROM [Senate].[BallotChoices]
    WHERE [Name] = @choice
      AND [BallotID] = @ballotId;

  SET @err =
    CASE
      WHEN @value IS NULL
        THEN 'A choice of ''' + @choice + ''' is not a valid ballot choice in'
             + ' this election.'
      WHEN @curVote IS NOT NULL
        THEN 'You have already voted during this voting session.'
    END;
  IF @err IS NOT NULL
    THROW 50000 , @err , 1;

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;

  IF @result = 0
    BEGIN
      INSERT [Senate].[Votes]
          ( [ElectionId] , [BallotId] , [Value] , [CastOn] , [CastBy] )
        VALUES( @electionId , @ballotId , @value , @castOn , @castBy );

      SET @voteId = SCOPE_IDENTITY();
      EXEC [Action].[RecordActionLogVotes] @logId , @voteId;
    END
  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Simple Action Point Requirement for the Casting of Votes" ,
"The [simple action point requirement][1] for [casting][2] a vote in the
senate shall be one (1) action point.

  [1]: OBJECT::[Action].[SimpleActionPointRequirements]
  [2]: OBJECT::[Senate].[Vote]" ,
"INSERT [Action].[SimpleActionPointRequirements] ( [ProcId] , [Points] )
  VALUES ( OBJECT_ID( '[Senate].[Vote]' ) , 1 );" ) ,
    ( "Tallying Results" ,
"The [tally of results][1] is in an election is the count of all votes cast
for each choice that appeared on the ballot for that election.

  [1]: OBJECT::[Senate].[TallyResults]" ,
"CREATE FUNCTION [Senate].[TallyResults](
    @electionId bigint )
RETURNS @results TABLE(
  [Value] tinyint ,
  [Name] sysname ,
  [Count] int ,
  [Percent] decimal( 10 , 5 ))
AS
BEGIN
  DECLARE @totalVotes int =
    ( SELECT ISNULL( NULLIF( COUNT(*) , 0 ) , 1 )
        FROM [Senate].[Votes]
        WHERE [ElectionId] = @electionId );
  WITH [Votes] ( [Value] , [Name] , [Count] )
    AS(
      SELECT c.[Value] , c.[Name] , COUNT(v.[Id])
        FROM [Senate].[Elections] e
        JOIN [Senate].[BallotChoices] c
          ON e.[BallotId] = c.[BallotId]
        LEFT JOIN [Senate].[Votes] v
          ON c.[Value] = v.[Value] AND e.[Id] = v.[ElectionId]
        WHERE e.[Id] = @electionId
        GROUP BY c.[Value] , c.[Name] )
    INSERT @results
    SELECT
        [Value] ,
        [Name] ,
        [Count] ,
        CAST( [Count] AS decimal( 18 , 9 )) * 100 / @totalVotes [Percent]
      FROM [Votes]
      ORDER BY [Value];
  RETURN;
END" ) ,
    ( "Definition of Voters" ,
"A [voter][1] may [cast votes][2] in elections in the senate, view any
[ballots][3], [ballot choices][4], [elections][5], [open elections][6],
[puplic votes][7], and [tallied results][8].

  [1]: ROLE::[Voter]
  [2]: OBJECT::[Senate].[Vote]
  [3]: OBJECT::[Senate].[Ballots]
  [4]: OBJECT::[Senate].[BallotChoices]
  [5]: OBJECT::[Senate].[Elections]
  [6]: OBJECT::[Senate].[PublicVotes]
  [7]: OBJECT::[Senate].[OpenElections]
  [8]: OBJECT::[Senate].[TallyResults]" ,
"CREATE ROLE [Voter];
GRANT EXECUTE ON OBJECT::[Senate].[Vote] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[Ballots] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[BallotChoices] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[Elections] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[PublicVotes] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[OpenElections] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[TallyResults] TO [Voter];" ) ,
    ( "Universal Suffrage of Citizens" ,
"Every [citizen][1] is a [voter][2].

  [1]: ROLE::[Citizen]
  [2]: ROLE::[Voter]" ,
"ALTER ROLE [Voter] ADD MEMBER [Citizen];" ) ,
    ( "The Standard Ballot" ,
"There shall be a [ballot][1] contain only two choices, *nay* and *yea*;
this shall be known as the [**standard ballot**][2].

  [1]: OBJECT::[Senate].[Ballots]
  [2]: OBJECT::[Senate].[GetStandardBallotId]" ,
"INSERT [Senate].[Ballots]
  DEFAULT VALUES;
DECLARE @ballotId nvarchar(30) = SCOPE_IDENTITY();
INSERT [Senate].[BallotChoices]
    ( [BallotId] , [Value] , [Name] )
  VALUES
    ( @ballotId , 0 , 'nay' ) ,
    ( @ballotId , 1 , 'yea' );

DECLARE @n char(2) = CHAR(13) + CHAR(10);
DECLARE @sql nvarchar(200) =
  'CREATE FUNCTION [Senate].[GetStandardBallotId]()' + @n
  + '  RETURNS int' + @n
  + 'AS' + @n
  + 'BEGIN' + @n
  + '  RETURN ' + @ballotId + ';' + @n
  + 'END';
EXEC ( @sql );" ) ,
    ( "Definition of a Call for Votes" ,
"A [call for votes][1] is a formal action to open an election for a bill. A
call for votes shall include the [bill][2] for which the call for votes was
made, the [election][3] that was opened in response to the call, the minimum
number of total votes required for the election to be considered valid
(called a *quorum*), the percentage of *yea* votes out the total votes
required to pass the bill, rounded to 5 decimal places (threshold), as well
as the date and time at which the call was made and the person who made the
call.

  [1]: OBJECT::[Senate].[CallsForVotes]
  [2]: OBJECT::[Senate].[Bills]
  [3]: OBJECT::[Senate].[Elections]" ,
"CREATE TABLE [Senate].[CallsForVotes](
  [BillId] bigint NOT NULL
                  PRIMARY KEY ,
  [ElectionId] bigint NOT NULL ,
  [Quorum] int NOT NULL ,
  [Threshold] decimal( 10 , 5 ) NOT NULL ,
  [CalledOn] datetime NOT NULL ,
  [CalledBy] int NOT NULL ,
  FOREIGN KEY ( [BillId] )
    REFERENCES [Senate].[Bills] ( [Id] ) ,
  FOREIGN KEY ( [ElectionId] )
    REFERENCES [Senate].[Elections] ( [Id] ));" ) ,
    ( "Quorum of Calls for Votes on Bills" ,
"Calls for votes on shall have a [quorum][1] equal to the one-half of the
current number of [voters][2], rounded up to the nearest integer.

  [1]: OBJECT::[Senate].[CalculateQuorum]
  [2]: ROLE::[Voter]" ,
"CREATE FUNCTION [Senate].[CalculateQuorum](
  @billId bigint )
  RETURNS int
AS
BEGIN
  RETURN (
    SELECT CEILING( COUNT( [principal_id] ) * .5 )
      FROM [sys].[database_principals]
      WHERE [type] = 'S'
        AND IS_ROLEMEMBER( 'Voter', [name] ) = 1 );
END" ) ,
    ( "Threshold of Calls for Votes on Bills" ,
"Calls for votes on bills shall have a [threshold][1] equal to 50.0.

  [1]: OBJECT::[Senate].[CalculateThreshold]" ,
"CREATE FUNCTION [Senate].[CalculateThreshold](
  @billId bigint )
  RETURNS decimal( 10 , 5 )
AS
BEGIN
  RETURN 50.0;
END" ) ,
    ( "Opening of Elections for Bills" ,
"An election that is created during a call for votes on a bill [shall open][1]
at the beginning of the hour after the call for votes is made.

  [1]: OBJECT::[Senate].[CalculateElectionOpenedOn]" ,
"CREATE FUNCTION [Senate].[CalculateElectionOpenedOn](
  @billId bigint ,
  @calledOn datetime )
  RETURNS datetime
AS
BEGIN
  RETURN DATEADD( HOUR , DATEDIFF( HOUR , 0 , @calledOn ) + 1 , 0 );
END" ) ,
    ( "Closing of Elections for Bills" ,
"An election that is created during a call for votes on a bill [shall
close][1] at the beginning of the hour after the election is opened.

  [1]: OBJECT::[Senate].[CalculateElectionClosedOn]" ,
"CREATE FUNCTION [Senate].[CalculateElectionClosedOn](
  @billId bigint ,
  @beginsOn datetime )
  RETURNS datetime
AS
BEGIN
  RETURN DATEADD( DAY , 3 , @beginsOn );
END" ) ,
    ( "Calling for Votes" ,
"To [call for votes][1] on a given bill is to perform the following procedure:

  1. if a call for votes had previously been made for said bill, raise an
     error and stop
  2. if the person calling for votes on said bill is not the same person
     that proposed said bill, raise an error and stop
  3. evaluate the simple action point requirement associated with this
     process
  4. open an election using the standard ballot
  5. record ancillary information in the activity log regarding this process
  6. record the call for votes that was made

  [1]: OBJECT::[Senate].[CalculateElectionClosedOn]" ,
"CREATE PROCEDURE [Senate].[CallForVotes]
  @billId int ,
  @electionId bigint = NULL OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @calledBy int = USER_ID() ,
          @calledOn datetime = GETUTCDATE() ,
          @proposedBy int ,
          @ballotId int = [Senate].[GetStandardBallotId]() ,
          @logId bigint ,
          @err nvarchar(400) ,
          @openedOn datetime ,
          @closedOn datetime ,
          @quorum int ,
          @threshold decimal( 10 , 5 ) ,
          @result int = -1;
  SET @err =
    CASE
      WHEN @billId IS NULL
        THEN N'Paremeter @billId may not be null.'
      WHEN NOT EXISTS( SELECT * FROM [Senate].[Bills] WHERE [Id] = @billId )
        THEN N'No such bill exists.'
      WHEN EXISTS( SELECT *
                     FROM [Senate].[CallsForVotes]
                     WHERE [BillId] = @billId )
        THEN N'A bill may not be called for votes more than once.'
    END;
  IF @err IS NOT NULL
    THROW 50000 , @err , 1;

  SET @openedOn =
    [Senate].[CalculateElectionOpenedOn]( @billId , @calledOn );
  SET @closedOn =
    [Senate].[CalculateElectionClosedOn]( @billId , @openedOn );
  SET @quorum = [Senate].[CalculateQuorum]( @billId );
  SET @threshold = [Senate].[CalculateThreshold]( @billId );
  SELECT @proposedBy = [ProposedBy]
    FROM [Senate].[Bills]
    WHERE [Id] = @billId;

  IF @proposedBy <> @calledBy
    BEGIN
      SET @err =
        'A call for votes on a bill may only be made by its proposer.';
      THROW 50000 , @err , 1;
    END

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;

  IF @result = 0
    BEGIN
      INSERT [Senate].[Elections]
          ( [BallotId] , [IsPublic] , [OpenedOn] , [ClosedOn] )
        VALUES
          ( @ballotId , 1 , @openedOn , @closedOn );
      SELECT @electionId = SCOPE_IDENTITY();
      EXEC [Action].[RecordActionLogBills] @logId , @billId;

      INSERT [Senate].[CallsForVotes](
          [BillId] ,
          [ElectionId] ,
          [Quorum] ,
          [Threshold] ,
          [CalledOn] ,
          [CalledBy] )
        VALUES(
          @billId ,
          @electionId ,
          @quorum ,
          @threshold ,
          @calledOn ,
          @calledBy );
    END

  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Simple Action Point Requirement for the Calling for Votes" ,
"The [simple action point requirement][1] for [casting][2] a vote in the
senate shall be five (5) action points.

  [1]: OBJECT::[Action].[SimpleActionPointRequirements]
  [2]: OBJECT::[Senate].[CallsForVotes]" ,
"INSERT [Action].[SimpleActionPointRequirements] ( [ProcId] , [Points] )
  VALUES ( OBJECT_ID( '[Senate].[CallsForVotes]' ) , 5 );" ) ,
    ( "Access to Calls for Votes" ,
"Any [senator][1] may [call for votes][2]. Any [voter][3], view [calls for
votes][4], view the [standard ballot id][5], calculate the [quorum][6] and
[threshold][7] for a call for votes on a bill, and the [opening][8] and
[closing][9] date for an election associated with a call for votes on a
bill.

  [1]: ROLE::[Senator]
  [2]: OBJECT::[Senate].[CallForVotes]
  [1]: ROLE::[Voter]
  [4]: OBJECT::[Senate].[GetStandardBallotId]
  [5]: OBJECT::[Senate].[CalculateQuorum]
  [6]: OBJECT::[Senate].[CalculateThreshold]
  [7]: OBJECT::[Senate].[CalculateElectionOpenedOn]
  [8]: OBJECT::[Senate].[CalculateElectionClosedOn]
  [8]: OBJECT::[Senate].[CallsForVotes]" ,
"GRANT EXECUTE ON OBJECT::[Senate].[CallForVotes] TO [Senator];
GRANT EXECUTE ON OBJECT::[Senate].[GetStandardBallotId] TO [Voter];
GRANT EXECUTE ON OBJECT::[Senate].[CalculateQuorum] TO [Voter];
GRANT EXECUTE ON OBJECT::[Senate].[CalculateThreshold] TO [Voter];
GRANT EXECUTE ON OBJECT::[Senate].[CalculateElectionOpenedOn] TO [Voter];
GRANT EXECUTE ON OBJECT::[Senate].[CalculateElectionClosedOn] TO [Voter];
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[CallsForVotes] TO [Voter];" );

EXEC [Imperium].[Enact]
    "Senatorial Voting Procedure" ,
"To provide an orderly democratic process within the Imperial Senate, the
Imperitor of the Imperium, Archon, does hereby proclaim," ,
    @clauses;
DELETE @clauses
GO