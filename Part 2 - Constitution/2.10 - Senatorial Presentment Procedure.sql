-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 8 : Senatorial Presentment Procedure
 * To allow for bills passed in the senate to be presented to the Imperitor for
 * enactment into law, the Imperitor of the Imperium, Archon, does hereby
 * proclaim,
*******************************************************************************/

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "Senatorial Presentment Procedure";
SET @preamble =
"To allow for bills passed in the senate to be presented to the Imperitor for
enactment into law, the Imperitor of the Imperium, Archon, does hereby
proclaim,";
DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Definition of Presentments" ,
"A [presentment][1] shall consist of a reference to a [bill][2] proposed in
the senate, the date and time the bill is presented, the name of the
presenter of the bill, the date and time that the presentment is received,
the name of the receiver of the presentment, and a value indicating whether
the bill was ratified or vetoed. If ratified, presentment shall also include
the ID of the enacted [law][3] associated with the ratified bill. If vetoed,
presentment shall also include a statement indicating why the bill was
vetoed.

  [1]: OBJECT::[Senate].[Presentments]
  [2]: OBJECT::[Senate].[Bills]
  [3]: OBJECT::[Imperium].[Laws]" ,
"CREATE TABLE [Senate].[Presentments](
  [BillId] bigint NOT NULL
           PRIMARY KEY ,
  [LawId] bigint NULL ,
  [PresentedOn] datetime NOT NULL ,
  [PresentedBy] int NOT NULL ,
  [ReceivedOn] datetime NULL ,
  [ReceivedBy] int NULL ,
  [Vetoed] bit NULL ,
  [ErrorClause] int NULL ,
  [Statement] nvarchar(4000) NULL ,
  FOREIGN KEY ( [BillId] )
    REFERENCES [Senate].[Bills]( [Id] ) ,
  FOREIGN KEY ( [LawId] )
    REFERENCES [Imperium].[Laws]( [Id] ));" ) ,
    ( "Presentment Messages Format" ,
"[Presentment messages][1] shall conform to a defined [schema][2] and contain
the ID of the bill, the ID of the person presenting the bill, and the date
and time that the presentment was created.

  [1]: MESSAGE TYPE::[//Imperium/Messages/Presentment]
  [2]: XML SCHEMA COLLECTION::[Senate].[PresentmentMessageSchema]" ,
"CREATE XML SCHEMA COLLECTION [Imperium].[PresentmentMessageSchema]
AS
N'<?xml version=""1.0"" encoding=""UTF-16""?>
<xsd:schema xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" >
  <xsd:element name=""presentment"">
    <xsd:complexType>
      <xsd:sequence> 
        <xsd:element name=""billId"" type=""xsd:long"" />
        <xsd:element name=""by"" type=""xsd:int"" />
        <xsd:element name=""on"" type=""xsd:dateTime"" />
      </xsd:sequence> 
    </xsd:complexType>
  </xsd:element>
</xsd:schema>'
CREATE MESSAGE TYPE [//Imperium/Messages/Presentment]
  VALIDATION = VALID_XML
    WITH SCHEMA COLLECTION [Imperium].[PresentmentMessageSchema];" ) ,
    ( "Presentment Contract" ,
"The [presentment contract][1] describes a conversation that consists solely
of the initiator sending [presentment messages][2].

  [1]: CONTRACT::[//Imperium/Contract/Presentment]
  [2]: MESSAGE TYPE::[//Imperium/Messages/Presentment]" ,
"CREATE CONTRACT [//Imperium/Contract/Presentment]
  ( [//Imperium/Messages/Presentment] SENT BY INITIATOR );" ) ,
    ( "Presentment Queue" ,
"The office of the Imperitor shall maintain a [queue][1] of presentments and a
[service][2] for the posting presentments to the presentment queue.

  [1]: OBJECT::[Imperium].[PresentmentQueue]
  [2]: SERVICE::[//Imperium/Service/Presentment]" ,
"CREATE QUEUE [Imperium].[PresentmentQueue];
CREATE SERVICE [//Imperium/Service/Presentment]
  ON QUEUE [Imperium].[PresentmentQueue]
    ( [//Imperium/Contract/Presentment] );" ) ,
    ( "Presentment Ceremony" ,
"During a [presentment ceremony][1] the Imperitor shall perform the following
procedure:

  1. said presentment is received by the office of the Imperitor
  2. the presented bill is either ratified into law or vetoed
  3. said presentment is updated to note the date and time it was received,
     the receiver of the presentment, and a value indicating whether the
     bill was ratified or vetoed shall be recorded
    * if ratified, said presentment is updated to note the number of the
      newly ratified law
    * if vetoed, said presentment is updated to include a statement
      indicating reason for the veto of the bill
  4. repeat steps 1 through 3 until the presentment queue is empty

  [1]: OBJECT::[Imperium].[PresentmentCeremony]" ,
"CREATE PROCEDURE [Imperium].[PresentmentCeremony]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @handle uniqueidentifier ,
          @message nvarchar( 4000 ) ,
          @msgTypName sysname ,
          @lawId bigint ,
          @errClause int ,
          @err nvarchar(4000) ,
          @result int = -1;
  WHILE 1 = 1
    BEGIN
      WAITFOR
        ( RECEIVE TOP (1)
              @handle = [conversation_handle] ,
              @message = [message_body] ,
              @msgTypName = [message_type_name]
            FROM [Imperium].[PresentmentQueue] ) ,
        TIMEOUT 5000;

      IF @@ROWCOUNT = 0
        BREAK;
      ELSE IF @msgTypName = '//Imperium/Messages/Presentment'
        BEGIN
          DECLARE @billId bigint ,
                  @xml xml( [Imperium].[PresentmentMessageSchema] ) = @message;
          SELECT @billId = @xml.value( 'presentment[1]/billId' , 'bigint' );
          SELECT @billId = [BillId]
            FROM [Senate].[Presentments]
            WHERE [BillId] = @billId AND [ReceivedOn] IS NULL;
          IF @billId IS NULL
            CONTINUE;

          UPDATE [Senate].[Presentments]
            SET
              [ReceivedOn] = GETUTCDATE() ,
              [ReceivedBy] = USER_ID()
            WHERE [BillId] = @billId;

          BEGIN TRY
            EXEC @result = [Imperium].[Ratify]
              @billId ,
              @lawId = @lawId OUTPUT ,
              @errorClause = @errClause OUTPUT ,
              @errorMessage = @err OUTPUT;
          END TRY
          BEGIN CATCH
            SET @err = ERROR_MESSAGE();
          END CATCH

          UPDATE [Senate].[Presentments]
            SET
              [LawId] = @lawId ,
              [Vetoed] = IIF( @lawId IS NULL , 1 , 0 ) ,
              [ErrorClause] = @errClause ,
              [Statement] = @err
            WHERE [BillId] = @billId;
        END
    END
  SET NOCOUNT OFF;
END" ) ,
    ( "Presentment Queue Activation" ,
"When messages arrive in the [presentment queue][1], the Office of the
Imperitor shall respond by holding a [presentment ceremony][2]

  [1]: OBJECT::[Imperium].[PresentmentQueue]
  [2]: OBJECT::[Imperium].[PresentmentCeremony]" ,
"ALTER QUEUE [Imperium].[PresentmentQueue]
  WITH ACTIVATION(
    STATUS = ON ,
    PROCEDURE_NAME = [Imperium].[PresentmentCeremony] ,
    MAX_QUEUE_READERS = 1 ,
    EXECUTE AS SELF );" ) ,
    ( "Presentment Procedure" ,
"To [present][1] a given bill is to perform the following procedure:

 1.   if no bill was specified, raise an error and stop
 2.   if said bill is not found in the set of proposed bills, raise an error
      and stop
 3.   if no election is associated with said bill, raise an error and stop
 4.   if the election associated for said bill has not yet closed, raise an
      error and stop
 5.   if the quorum was not met for said election, raise an error and stop
 6.   if the percentage of *yea* votes tallied in the results of said
      election is less than or equal to fify percent (50%), raise an error
      and stop
 7.   if the person presenting the bill is not the same person that proposed
      the bill, raise an error and stop
 8.   evaluate the action point requirement associated with this process
 9.   record the presentment in the ledger of the senate
 10.  send a presentment message to the presentment service of the office of
      the Imperitor
 10.  record ancillary information in the activity log regarding this process

  [1]: OBJECT::[Senate].[Present]" ,
"CREATE PROCEDURE [Senate].[Present]
  @billId int
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @presentedBy int = USER_ID() ,
          @presentedOn datetime = GETUTCDATE() ,
          @proposedBy int ,
          @electionId int ,
          @quorum int ,
          @closedOn datetime ,
          @totalVotes int ,
          @percent real ,
          @logId bigint ,
          @now datetime = GETUTCDATE() ,
          @err nvarchar( 400 ) ,
          @result int = -1;
   IF @billId IS NULL
    THROW 50000 , 'Parameter @billId may not be null.' , 1;
  
  SELECT
      @billId = b.[Id] ,
      @proposedBy = b.[ProposedBy] ,
      @electionId = e.[Id] ,
      @quorum = e.[Quorum] ,
      @closedOn = e.[ClosedOn] ,
      @totalVotes = COUNT( v.[Id] )
    FROM [Senate].[Bills] b
    JOIN [Senate].[Elections] e ON b.[ElectionId] = e.[Id]
    LEFT JOIN [Senate].[Votes] v ON e.[Id] = v.[ElectionId]
    WHERE b.[Id] = @billId
    GROUP BY b.[Id] , b.[ProposedBy] , e.[Id] , e.[Quorum] , e.[ClosedOn];
  SELECT @percent = [Percent]
    FROM [Senate].[TallyResults]( @electionId )
    WHERE [Name] = 'yea';
  SET @err =
    CASE
      WHEN @billId IS NULL
        THEN 'Specified bill was not found.'
      WHEN @electionId IS NULL
        THEN 'The specified bill has no associated election.'
      WHEN @closedOn >= @now
        THEN 'The election associated with specified bill has not closed.'
      WHEN @totalVotes < @quorum
        THEN 'A quorum has not been met in the election associated with'
             + ' specified bill.'
      WHEN @percent <= 0.5
        THEN 'More that 50% of the votes must be ''yea'' in order to pass this'
             + ' bill.'
    END;

  IF @err IS NOT NULL
    THROW 50000 , @err , 1;

  IF ( @proposedBy <> @presentedBy 
         AND IS_ROLEMEMBER( 'President' , USER_NAME() ) = 0 )
    BEGIN
      SET @err =
        'Only a bill''s proposer or the President of the Senate may present'
        + ' a bill.';
      THROW 50000 , @err , 1;
    END

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId OUTPUT;
  IF @result = 0
    BEGIN
      INSERT [Senate].[Presentments]
          ( [BillId] , [PresentedOn] , [PresentedBy] )
        VALUES
          ( @billId , @presentedOn, @presentedBy );

      DECLARE @handle uniqueidentifier ,
              @xml xml( [Imperium].[PresentmentMessageSchema] )
      SET @xml = 
        ( SELECT 
              1 [Tag],
              NULL [Parent],
              @billId [presentment!1!billId!ELEMENT] ,
              @presentedBy [presentment!1!by!ELEMENT] ,
              @presentedOn [presentment!1!on!ELEMENT]
            FOR XML EXPLICIT );
      BEGIN DIALOG @handle
        FROM SERVICE [//Imperium/Service/Presentment]
        TO SERVICE '//Imperium/Service/Presentment'
        ON CONTRACT [//Imperium/Contract/Presentment]
        WITH ENCRYPTION = OFF;
      SEND ON CONVERSATION @handle
        MESSAGE TYPE [//Imperium/Messages/Presentment] ( @xml );
      END CONVERSATION @handle;

      EXEC [Action].[RecordActionLogBills] @logId , @billId;
    END

  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Action Point Requirement for the Presentment of Bills" ,
"The [action point requirement][1] for [presenting][2] a bill to the
Imperitor shall be five (20) action points.

  [1]: OBJECT::[Action].[ActionPointRequirements]
  [2]: OBJECT::[Senate].[Present]" ,
"INSERT [Action].[ActionPointRequirements] ( [ProcId] , [Points] )
  VALUES ( OBJECT_ID( '[Senate].[Present]' ) , 20 );" ) ,
    ( "Access to the Presentment Process" ,
"All [senators][1] shall have the right to [present][2] bills proposed in the
senate, and all [citizens][3] shall have the right to view any
[presentments][4] made in the senate.

  [1]: ROLE::[Senator]
  [2]: OBJECT::[Senate].[Present]
  [3]: ROLE::[Citizen]
  [4]: OBJECT::[Imperium].[Senate].[Presentments]" ,
"GRANT EXECUTE ON OBJECT::[Senate].[Present] TO [Senator];
GRANT EXECUTE ON OBJECT::[Senate].[Present] TO [President];
GRANT SELECT ON OBJECT::[Senate].[Presentments] TO [Citizen];" );

EXEC [Imperium].[Enact] @name , @preamble , @clauses;
GO
