-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 6 : Charter of the Imperial Senate
 * To provide for the self-determination of the citizenry of the Imperium, the
 * Imperitor of the Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Establishment of the Senate" ,
"Legislative power within the Imperium shall be held by the the [Imperial
Senate][1], hereafter.

  [1]: SCHEMA::[Senate]" ,
"CREATE SCHEMA [Senate];" ) ,
    ( "Definition of Bills" ,
"A [bill][1] within the senate shall consist of a name, a preamble, the date
and time the bill was proposed in the senate, the name of the individual that
proposed the bill, and one or more [clauses][2].

  [1]: OBJECT::[Senate].[Bills]
  [2]: OBJECT::[Senate].[Clauses]" ,
"CREATE TABLE [Senate].[Bills](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [Name] sysname NOT NULL ,
  [Preamble] nvarchar(4000) NOT NULL ,
  [ProposedBy] int NOT NULL ,
  [ProposedOn] datetime NOT NULL );" ) ,
    ( "Definition of Bill Clauses" ,
"A [clause][1] of a [bill][2] shall consist of an optional name, a description
writen in clear, plain English and a valid, an executable SQL statement, and
a number indicating its position within the set of clauses of the bill.

  [1]: OBJECT::[Senate].[Clauses]
  [2]: OBJECT::[Senate].[Bills]" ,
"CREATE TABLE [Senate].[Clauses](
  [BillId] bigint NOT NULL ,
  [ClauseNumber] int NOT NULL ,
  [Name] sysname NULL ,
  [English] nvarchar(4000) NOT NULL ,
  [Statement] nvarchar(4000) NOT NULL ,
  PRIMARY KEY ( [BillId] , [ClauseNumber] ) ,
  FOREIGN KEY ( [BillId] ) REFERENCES [Senate].[Bills] ( [Id]) );" ) ,
    ( "Ratification Process" ,
"To [ratify][1] a [bill][2] is to [enact][3] that bill as a law.

  [1]: OBJECT::[Senate].[Ratify]
  [2]: OBJECT::[Senate].[Bills]
  [3]: OBJECT::[Imperium].[Enact]" ,
"CREATE PROCEDURE [Imperium].[Ratify](
  @billId bigint ,
  @lawId bigint = NULL OUTPUT ,
  @errorMessage nvarchar(4000) = NULL OUTPUT )
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @name sysname ,
          @preamble nvarchar(4000) ,
          @result int ,
          @clauses [Imperium].[ClauseTable];

  SELECT
      @name = [Name] ,
      @preamble = [Preamble]
    FROM [Senate].[Bills]
    WHERE [Id] = @billId;

  INSERT @clauses
    SELECT
        [Name] ,
        [English] ,
        [Statement]
      FROM [Senate].[Clauses]
      WHERE [BillId] = @billId
      ORDER BY [ClauseNumber] ASC;

  EXEC @result = [Imperium].[Enact]
    @name = @name ,
    @preamble = @preamble ,
    @clauses = @clauses ,
    @lawId = @lawId OUTPUT ,
    @errorMessage = @errorMessage OUTPUT;

  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Ancillary Action Log Regarding Senatorial Bills (I)" ,
"The [action log][1] shall include [ancillary information][2] regarding
[bills][3] proposed in the [senate][4].

  [1]: OBJECT::[Action].[Log]
  [2]: OBJECT::[Action].[ActionLogBills]
  [3]: OBJECT::[Senate].[Bills]
  [4]: SCHEMA::[Senate]" ,
"CREATE TABLE [Action].[ActionLogBills](
  [LogId] bigint NOT NULL ,
  [BillId] bigint NOT NULL ,
  FOREIGN KEY ( [LogId] ) REFERENCES [Action].[ActionLog]( [Id] ) ,
  FOREIGN KEY ( [BillId] ) REFERENCES [Senate].[Bills]( [Id] ) );" ) ,
    ( "Ancillary Action Log Regarding Senatorial Bills (II)" ,
"[Ancillary information][1] in a person's [action log][2] regarding bills
proposed in the senate shall be a [component][3] of that person's [personal
profile][4].

  [1]: OBJECT::[Action].[ActionLogBills]
  [2]: OBJECT::[Action].[ActionLog]
  [3]: OBJECT::[My].[ActionLogBills]
  [4]: SCHEMA::[My]" ,
"CREATE VIEW [My].[ActionLogBills]
AS
SELECT
    x.[LogId] ,
    x.[BillId]
  FROM [Action].[ActionLogBills] x
  JOIN [Action].[ActionLog] y ON x.[LogId] = y.[Id];" ) ,
    ( "Ancillary Action Log Regarding Senatorial Bills (III)" ,
"Recording [ancillary information][1] in the [action log][2] regarding bills
proposed in the senate is done by noting the ID of the bill in the action
log.

  [1]: OBJECT::[Action].[RecordActionLogBills]
  [2]: OBJECT::[My].[ActionLog]
  [3]: SCHEMA::[My]" ,
"CREATE PROCEDURE [Action].[RecordActionLogBills]
  @LogId bigint ,
  @BillId bigint
AS
BEGIN
  IF @LogId IS NULL OR @BillId IS NULL
    THROW 50000 , 'All parameters must be non-null.' , 1;
  ELSE
    INSERT [Action].[ActionLogBills]( [LogId] , [BillId] )
      VALUES( @LogId , @BillId );
END" ) ,
    ( "Proposal of Bills" ,
"To [propose a bill][1] in the senate is to perform the following procedure:

  1. evaluate the simple action point requirement associated with this
     process
  2. read the name and preamble of the bill on the floor of the senate
  3. record ancillary information in the activity log regarding this process
  4. read the name and english and sql components of each clause on the floor
     of the senate in order

  [1]: OBJECT::[Senate].[Propose]" ,
"CREATE PROCEDURE [Senate].[Propose]
  @name sysname ,
  @preamble nvarchar(4000) ,
  @clauses [Imperium].[ClauseTable] READONLY ,
  @billId bigint = NULL OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @result int = -1,
          @logId bigint;

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;

  IF @result = 0
    BEGIN
      INSERT [Senate].[Bills]
          ( [Name] , [Preamble] , [ProposedBy] , [ProposedOn] )
        VALUES ( @name , @preamble, USER_ID() , GETUTCDATE() );
      SELECT @billId = SCOPE_IDENTITY();

      EXEC [Action].[RecordActionLogBills] @logId , @billId;

      INSERT [Senate].[Clauses]
          ( [BillId] , [Name] , [English] , [Statement] , [ClauseNumber] )
        SELECT @billId , [Name] , [English] , [Statement] , [ClauseNumber]
          FROM @clauses;
    END

  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Simple Action Point Requirement for the Proposal of Bills" ,
"The [simple action point requirement][1] for [proposing][2] a bill in the
senate shall be twenty (20) action points.

  [1]: OBJECT::[Senate].[SimpleActionPointRequirements]
  [2]: OBJECT::[Senate].[Propose]" ,
"INSERT [Action].[SimpleActionPointRequirements] ( [ProcId] , [Points] )
  VALUES ( OBJECT_ID( '[Senate].[Propose]' ) , 5 );" ) ,
    ( "Membership of the Senate" ,
"Members of the senate are known as [senators][1]. All [senators][1] may
inspect any object in the [senate][2], view any [bills][3] that have been
proposed in the senate and their [clauses][4], and propose new [bills][5].

  [1]: ROLE::[Senator]
  [2]: SCHEMA::[Senate]
  [3]: OBJECT::[Senate].[Bills]
  [4]: OBJECT::[Senate].[Clauses]
  [5]: OBJECT::[Senate].[Propose]" ,
"CREATE ROLE [Senator]
GRANT VIEW DEFINITION ON SCHEMA::[Senate] TO [Senator];
GRANT SELECT , REFERENCES ON OBJECT::[Senate].[Bills] TO [Senator];
GRANT SELECT , REFERENCES ON OBJECT::[Senate].[Clauses] TO [Senator];
GRANT EXECUTE ON OBJECT::[Senate].[Propose] TO [Senator];" ) ,
    ( "Universal Democracy" ,
"Every [citizen][1] is a [senator][2].

  [1]: ROLE::[Citizen]
  [2]: ROLE::[Senator]" ,
"ALTER ROLE [Senator] ADD MEMBER [Citizen];" );

EXEC [Imperium].[Enact]
    "Charter of the Imperial Senate" ,
"To provide for the self-determination of the citizenry of the Imperium, the
Imperitor of the Imperium, Archon, does hereby proclaim," ,
    @clauses;
GO

