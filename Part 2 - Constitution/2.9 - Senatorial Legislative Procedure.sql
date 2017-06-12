-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 9 : Senatorial Legislative Procedure
 * To provide a legislative process for the passage of laws within the Imperial
 * Senate, the Imperitor of the Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "Senatorial Legislative Procedure";
SET @preamble =
"To provide a legislative process for the passage of laws within the Imperial
Senate, the Imperitor of the Imperium, Archon, does hereby proclaim,";
DECLARE @clauses [Imperium].[ClauseTable];
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Elections for Bills" ,
"All [bills][1] may be associated with an [election][2].

  [1]: OBJECT::[Senate].[Bills]
  [2]: OBJECT::[Senate].[Elections]" ,
"ALTER TABLE [Senate].[Bills]
  ADD
    [ElectionId] bigint NULL ,
    FOREIGN KEY ( [ElectionId] )
      REFERENCES [Senate].[Elections]( [Id] );" ) ,
    ( "The Standard Ballot" ,
"A [ballot shall be created][1] contain only two choices, *nay* and *yea*;
this shall be known as the [**standard ballot**][2].

  [1]: OBJECT::[Senate].[CreateBallot]
  [2]: OBJECT::[Senate].[GetStandardBallotId]" ,
"DECLARE @ballotId int;
DECLARE @ballotChoices [Senate].[BallotChoiceTable];
INSERT @ballotChoices
    ( [Value] , [Name] )
  VALUES
    ( 0 , 'nay' ) ,
    ( 1 , 'yea' );
EXEC [Senate].[CreateBallot] @ballotChoices , @ballotId = @ballotId OUTPUT;

DECLARE @n char(2) = CHAR(13) + CHAR(10);
DECLARE @sql nvarchar( 200 ) =
  CONCAT(
    'CREATE FUNCTION [Senate].[GetStandardBallotId]()' , @n ,
    '  RETURNS int' , @n ,
    'AS' , @n ,
    'BEGIN' , @n ,
    '  RETURN ' , @ballotId , ';' , @n ,
    'END' );
EXEC ( @sql );" ) ,
    ( "Calling for Votes on a Bill" ,
"To [call for votes][1] on a given bill is to perform the following procedure:

 1. if the opening of closing date and time ar null, raise an error and stop
 2. if the opening date is greater than or equal to the closing date, raise
    an error and stop
 3. if no ballot is specified, the [standard ballot][2] shall be used
 4. if no quorum is specified, the value of 50% of the current number of
    voters, rounded up to the nearest integer, shall be used
 5. create a new ballot
 6. add each value and name pair from said table of ballot choices to the
    newly created ballot

  [1]: OBJECT::[Senate].[CreateElection]
  [2]: OBJECT::[Senate].[GetStandardBallotId]" ,
"CREATE PROCEDURE [Senate].[CallForVotes]
  @billId bigint ,
  @electionId bigint = NULL OUTPUT
  WITH EXECUTE AS CALLER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @calledBy int = USER_ID() ,
          @proposedBy int ,
          @openedOn datetime ,
          @closedOn datetime ,
          @quorum int ,
          @ballotId int ,
          @logId bigint ,
          @result int = -1;

  IF @billId IS NULL
    THROW 50000 , '@billId may not be null.' , 1;
  SELECT
      @billId = [Id] ,
      @proposedBy = [ProposedBy] ,
      @electionId = [ElectionId]
    FROM [Senate].[Bills]
    WHERE [Id] = @billId;
  IF @billId IS NULL
    THROW 50000 , 'Specified bill not found.' , 1;
  IF @electionId IS NOT NULL
    THROW 50000 , 'An election has already been called for specified bill.' , 1;
  IF ( @proposedBy <> @calledBy 
         AND IS_ROLEMEMBER( 'President' , USER_NAME() ) = 0 )
    BEGIN
      DECLARE @err nvarchar( 100 ) =
        'Only a bill''s proposer or the President of the Senate may call for'
        + ' votes on a bill.';
      THROW 50000 , @err , 1;
    END

  SET @ballotId = [Senate].[GetStandardBallotId]();
  SELECT @quorum = CEILING( COUNT( [principal_id] ) * .5 )
    FROM [Imperium].[GetAllRoleMembers]( USER_ID( 'Voter' ) );
  SET @openedOn = DATEADD( HOUR , DATEDIFF( HOUR , 0 , GETUTCDATE() ) + 1 , 0 );
  SET @closedOn = DATEADD( DAY , 6 , @openedOn );

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;

  IF @result = 0
    BEGIN
      INSERT [Senate].[Elections](
          [BallotId] ,
          [Quorum] ,
          [OpenedOn] ,
          [OpenedBy] ,
          [ClosedOn] ,
          [ClosedBy] )
        VALUES(
          @ballotId ,
          @quorum ,
          @openedOn ,
          @calledBy ,
          @closedOn ,
          @calledBy );
      SET @electionId = SCOPE_IDENTITY();

      UPDATE [Senate].[Bills]
        SET [ElectionId] = @electionId
        WHERE [Id] = @billId;

      EXEC [Action].[RecordActionLogBills] @logId , @billId;
      EXEC [Action].[RecordActionLogElections] @logId , @electionId;
    END
  SET NOCOUNT OFF;
  RETURN 0;
END" ) ,
    ( "Action Point Requirement for the Calling for Votes" ,
"The [action point requirement][1] for [calling for votes][2] on a bill in the
senate shall be five (5).

  [1]: OBJECT::[Action].[ActionPointRequirements]
  [2]: OBJECT::[Senate].[CallsForVotes]" ,
"INSERT [Action].[ActionPointRequirements] ( [ProcId] , [Points] )
  VALUES( OBJECT_ID( '[Senate].[CallForVotes]' ) , 5  );" ) ,
    ( "Immediately Opening an Election" ,
"To [immediately open][1] a given election is to perform the following
process:

 1. if said election is currently open, raise an error and stop
 2. if said election is currently closed, raise an error and stop
 3. evaluate the action point requirement associated with this process
 4. set the open date and time of the election to the current date and time
 5. record ancillary information in the activity log regarding this process

  [1]: OBJECT::[Senate].[OpenElection]" ,
"CREATE PROCEDURE [Senate].[OpenElection]
  @electionId bigint
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @now datetime = GETUTCDATE() ,
          @openedOn datetime ,
          @closedOn datetime ,
          @logId bigint ,
          @result int;
  SELECT
      @openedOn = [OpenedOn] ,
      @closedOn = [ClosedOn]
    FROM [Senate].[Elections]
    WHERE [Id] = @electionId;
  IF @closedOn < @now
    THROW 50000 , 'The election has already closed.' , 1;
  IF @openedOn < @now
    THROW 50000 , 'The election has already opened.' , 1;

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;

  IF @result = 0
    BEGIN
      UPDATE [Senate].[Elections]
        SET
          [OpenedOn] = @now ,
          [OpenedBy] = USER_ID()
        WHERE [Id] = @electionId;

      EXEC [Action].[RecordActionLogElections] @logId , @electionId;
    END
  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Action Point Requirement for Opening an Election" ,
"The [action point requirement][1] for [opening an election][2] on a bill in
the senate shall be five (5).

  [1]: OBJECT::[Action].[ActionPointRequirements]
  [2]: OBJECT::[Senate].[CallsForVotes]" ,
"INSERT [Action].[ActionPointRequirements] ( [ProcId] , [Points] )
  VALUES( OBJECT_ID( '[Senate].[OpenElection]' ) , 5  );" ) ,
    ( "Immediately Closing an Election" ,
"To [immediately close][1] a given election is to perform the following
process:

 1. if said election is not currently open, raise an error and stop
 2. if said election is currently closed, raise an error and stop
 3. if the quorum on election has not yet been met, raise an error and stop
 4. evaluate the action point requirement associated with this process
 5. set the open date and time of the election to the current date and time
 6. record ancillary information in the activity log regarding this process

  [1]: OBJECT::[Senate].[CloseElection]" ,
"CREATE PROCEDURE [Senate].[CloseElection]
  @electionId bigint
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @now datetime = GETUTCDATE() ,
          @quorum int ,
          @totalVotes int ,
          @openedOn datetime ,
          @closedOn datetime ,
          @logId bigint ,
          @result int;
  SELECT
      @quorum = [Quorum] ,
      @openedOn = [OpenedOn] ,
      @closedOn = [ClosedOn]
    FROM [Senate].[Elections]
    WHERE [Id] = @electionId;
  IF @closedOn < @now
    THROW 50000 , 'The election has already closed.' , 1;
  IF @openedOn >= @now
    THROW 50000 , 'The election has not opened.' , 1;
  SELECT @totalVotes = COUNT(*)
    FROM [Senate].[Votes]
    WHERE [ElectionId] = @electionId;
  IF @totalVotes < @quorum
    THROW 50000 , 'Quorum has not been beet.' , 1;

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;

  IF @result = 0
    BEGIN
      UPDATE [Senate].[Elections]
        SET
          [ClosedOn] = @now ,
          [ClosedBy] = USER_ID()
        WHERE [Id] = @electionId;

      EXEC [Action].[RecordActionLogElections] @logId , @electionId;
    END
  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Action Point Requirement for Closing an Election" ,
"The [action point requirement][1] for [closing an election][2] on a bill in
the senate shall be five (5).

  [1]: OBJECT::[Action].[ActionPointRequirements]
  [2]: OBJECT::[Senate].[CloseElection]" ,
"INSERT [Action].[ActionPointRequirements] ( [ProcId] , [Points] )
  VALUES( OBJECT_ID( '[Senate].[CloseElection]' ) , 5  );" ) ,
    ( "Access to Voting Procedures" ,
"Any [senator][1] may [call for votes][2] on bills and view [votes][3] cast
in the senate.

  [1]: ROLE::[Senator]
  [2]: OBJECT::[Senate].[CallForVotes]
  [3]: OBJECT::[Senate].[Votes]" ,
"GRANT EXECUTE ON OBJECT::[Senate].[CallForVotes] TO [Senator];
GRANT SELECT ON OBJECT::[Senate].[Votes] TO [Senator];" ) ,
    ( "Powers of the President of the Senate" ,
"The [President of the Senate][1] may [call for votes][2] on bills, as well as
[immediately open][3] or [close elections][4].

  [1]: ROLE::[President]
  [2]: OBJECT::[Senate].[OpenElection]
  [3]: OBJECT::[Senate].[CloseElection]" ,
"GRANT EXECUTE ON OBJECT::[Senate].[CallForVotes] TO [President];
GRANT EXECUTE ON OBJECT::[Senate].[OpenElection] TO [President];
GRANT EXECUTE ON OBJECT::[Senate].[CloseElection] TO [President];" );

EXEC [Imperium].[Enact] @name , @preamble , @clauses;
GO