-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 8 : Senatorial Electoral Procedure
 * To provide an orderly democratic process within the Imperial Senate, the
 * Imperitor of the Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "Senatorial Voting Procedure";
SET @preamble =
"To provide an orderly democratic process within the Imperial Senate, the
Imperitor of the Imperium, Archon, does hereby proclaim,";
DECLARE @clauses [Imperium].[ClauseTable];
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
  [Value] int NOT NULL ,
  [Name] sysname ,
  PRIMARY KEY ( [BallotId] , [Value] ) ,
  UNIQUE ( [BallotId] , [Name] ) ,
  FOREIGN KEY ( [BallotId] ) REFERENCES [Senate].[Ballots]( [Id] ));" ) ,
    ( "Definition of Elections" ,
"Votes shall be cast in [elections][1], which specify the rules under which
votes are to be cast, including a reference to the ballot that shall be used
for that election, and the period of time during which votes may be cast.

  [1]: OBJECT::[Senate].[Elections]" ,
"CREATE TABLE [Senate].[Elections](
  [Id] bigint NOT NULL
              IDENTITY ( 1, 1 )
              PRIMARY KEY ,
  [BallotId] int NOT NULL ,
  [Quorum] int NOT NULL ,
  [OpenedOn] datetime NOT NULL ,
  [OpenedBy] int NOT NULL ,
  [ClosedOn] datetime NOT NULL ,
  [ClosedBy] int NOT NULL ,
  UNIQUE ( [Id], [BallotId] ) ,
  FOREIGN KEY ( [BallotId] ) REFERENCES [Senate].[Ballots]( [Id] ));
CREATE NONCLUSTERED INDEX [IX_Elections_OpenedOn]
  ON [Senate].[Elections] ( [OpenedOn] );
CREATE NONCLUSTERED INDEX [IX_Elections_ClosedOn]
  ON [Senate].[Elections] ( [ClosedOn] );" ) ,
    ( "Definition of Open Elections" ,
"An [open election][1] is an election that was opened prior to or on the
current date and time and that will close after the current date and time.

  [1]: OBJECT::[Senate].[OpenElections]" ,
"CREATE VIEW [Senate].[OpenElections]
AS
SELECT
    [Id] ,
    [BallotId] ,
    [Quorum] ,
    [OpenedOn] ,
    [OpenedBy] ,
    [ClosedOn] ,
    [ClosedBy]
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
    [Quorum] ,
    [OpenedOn] ,
    [OpenedBy] ,
    [ClosedOn] ,
    [ClosedBy]
  FROM [Senate].[Elections]
  WHERE [ClosedOn] <= GETUTCDATE();" ) ,
    ( "Definition of Tables of Ballot Choices" ,
"A [table of ballot choices][1] is a collection of items which shall consist
of a numeric value and an optional name.

  [1]: TYPE::[Senate].[BallotChoiceTable]" ,
"CREATE TYPE [Senate].[BallotChoiceTable] AS TABLE(
  [Value] int NOT NULL
              PRIMARY KEY ,
  [Name] sysname );" ) ,
    ( "Creation of Ballots" ,
"To [create a ballot][1] with a given table of ballot choices is to perform
the following procedure:

 1. if said table contains fewer than 2 options, raise an error and stop
 2. create a new [ballot][2]
 3. add each value and name pair from said table of ballot choices to the
    set of [ballot choices][3] of the newly created ballot

  [1]: OBJECT::[Senate].[CreateBallot]
  [2]: OBJECT::[Senate].[Ballots]
  [3]: OBJECT::[Senate].[BallotChoices]" ,
"CREATE PROCEDURE [Senate].[CreateBallot]
  @ballotChoices [Senate].[BallotChoiceTable] READONLY ,
  @ballotId int OUTPUT
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @count int;
  SELECT @count = COUNT(*) FROM @ballotChoices;
  IF @count < 2
    THROW 50000 , 'Ballot must contain at least 2 coices' , 1;

  INSERT [Senate].[Ballots] DEFAULT VALUES;
  SET @ballotId = SCOPE_IDENTITY();
  INSERT [Senate].[BallotChoices]( [BallotId] , [Value] , [Name] )
    SELECT @ballotId , [Value] , [Name]
      FROM @ballotChoices;
  RETURN 0;
END" ) ,
    ( "Ancillary Action Log Regarding Elections (I)" ,
"The [action log][1] shall include [ancillary information][2] regarding
[votes][3] cast in the [senate][4].

  [1]: OBJECT::[Action].[Log]
  [2]: OBJECT::[Action].[ActionLogElections]
  [3]: OBJECT::[Senate].[Elections]
  [4]: SCHEMA::[Senate]" ,
"CREATE TABLE [Action].[ActionLogElections](
  [LogId] bigint NOT NULL ,
  [ElectionId] bigint NOT NULL ,
  FOREIGN KEY ( [LogId] ) REFERENCES [Action].[ActionLog]( [Id] ) ,
  FOREIGN KEY ( [ElectionId] ) REFERENCES [Senate].[Elections]( [Id] ) );" ) ,
    ( "Ancillary Action Log Regarding Elections (II)" ,
"[Ancillary information][1] in a person's [action log][2] regarding votes cast
in the senate shall be a [component][3] of that person's [personal
profile][4].

  [1]: OBJECT::[Action].[ActionLogElections]
  [2]: OBJECT::[Action].[ActionLog]
  [3]: OBJECT::[My].[ActionLogElections]
  [4]: SCHEMA::[My]" ,
"CREATE VIEW [My].[ActionLogElections]
AS
SELECT
    x.[LogId] ,
    x.[ElectionId]
  FROM [Action].[ActionLogElections] x
  JOIN [Action].[ActionLog] y ON x.[LogId] = y.[Id];" ) ,
    ( "Ancillary Action Log Regarding Votes Cast in the Senate (III)" ,
"Recording [ancillary information][1] in the [action log][2] regarding votes
cast in the senate is done by noting the ID of the bill in the action log.

  [1]: OBJECT::[Action].[RecordActionLogElections]
  [2]: OBJECT::[My].[ActionLog]
  [3]: SCHEMA::[My]" ,
"CREATE PROCEDURE [Action].[RecordActionLogElections]
  @LogId bigint ,
  @ElectionId bigint
AS
BEGIN
  IF @LogId IS NULL OR @ElectionId IS NULL
    THROW 50000 , 'All parameters must be non-null.' , 1;
  ELSE
    INSERT [Action].[ActionLogElections]( [LogId] , [ElectionId] )
      VALUES( @LogId , @ElectionId );
END" ) ,
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
  [Value] int NOT NULL ,
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
    ( "Votes as Profile Component" ,
"The history of a person's [votes][1] shall be a [component][2] of that
person's [personal profile][3].

  [1]: OBJECT::[Senate].[Votes]
  [2]: OBJECT::[My].[Votes]
  [3]: SCHEMA::[My]" ,
"CREATE VIEW [My].[Votes]
AS
SELECT
    [Id] ,
    [ElectionId] ,
    [BallotId] ,
    [Value] ,
    [CastOn] ,
    [CastBy]
  FROM [Senate].[Votes]
  WHERE [CastBy] = USER_ID();" ) ,
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
  4. evaluate the action point requirement associated with this process
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
          @value int ,
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
    ( "Action Point Requirement for the Casting of Votes" ,
"The [action point requirement][1] for [casting][2] a vote in the senate shall
be one (1) action point.

  [1]: OBJECT::[Action].[ActionPointRequirements]
  [2]: OBJECT::[Senate].[Vote]" ,
"INSERT [Action].[ActionPointRequirements] ( [ProcId] , [Points] )
  VALUES ( OBJECT_ID( '[Senate].[Vote]' ) , 1 );" ) ,
    ( "Tallying Results" ,
"The [tally of results][1] is in an election is the count of all votes cast
for each choice that appeared on the ballot for that election.

  [1]: OBJECT::[Senate].[TallyResults]" ,
"CREATE FUNCTION [Senate].[TallyResults](
    @electionId bigint )
RETURNS @results TABLE(
  [Value] int ,
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
"Persons who vote within elections shall be [voters][1].

  [1]: ROLE::[Voter]" ,
"CREATE ROLE [Voter]" ) ,
    ( "Rights of Voters" ,
"A [voter][1] may [cast votes][2] in elections in the senate, view any
[bills][3] that have been proposed in the senate and their [clauses][4], view
[ballots][5] and [ballot choices][6], create [ballot choice tables][7], view
[elections][8], [open elections][9], [closed elections][10], [votes][11], and
[tallied results][12].

  [1]: ROLE::[Voter]
  [2]: OBJECT::[Senate].[Vote]
  [3]: OBJECT::[Senate].[Bills]
  [4]: OBJECT::[Senate].[Clauses]
  [3]: OBJECT::[Senate].[Ballots]
  [4]: OBJECT::[Senate].[BallotChoices]
  [5]: TYPE::[Senate].[BallotChoiceTable]
  [6]: OBJECT::[Senate].[Elections]
  [7]: OBJECT::[Senate].[PublicVotes]
  [8]: OBJECT::[Senate].[OpenElections]
  [9]: OBJECT::[Senate].[ClosedElections]
  [10]: OBJECT::[Senate].[TallyResults]" ,
"GRANT EXECUTE ON OBJECT::[Senate].[Vote] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[Bills] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[Clauses] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[Ballots] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[BallotChoices] TO [Voter];
GRANT EXECUTE ON TYPE::[Senate].[BallotChoiceTable] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[Elections] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[OpenElections] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[ClosedElections] TO [Voter];
GRANT SELECT ON OBJECT::[Senate].[TallyResults] TO [Voter];" );

EXEC [Imperium].[Enact] @name , @preamble , @clauses;
GO
