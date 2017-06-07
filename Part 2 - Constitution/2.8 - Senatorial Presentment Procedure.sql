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
          @err nvarchar(4000) ,
          @result int = -1;
  WHILE 1 = 1
    BEGIN
      WAITFOR
        ( RECEIVE TOP (1)
              @handle = [conversation_handle] ,
              @message = [message_body] ,
              @msgTypName = [message_type_name]
            FROM [Senate].[PresentmentQueue] ) ,
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
              @errorMessage = @err OUTPUT;
          END TRY
          BEGIN CATCH
            SET @err = ERROR_MESSAGE();
          END CATCH

          UPDATE [Senate].[Presentments]
            SET
              [LawId] = @lawId ,
              [Vetoed] = IIF( @lawId IS NULL , 1 , 0 ) ,
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

  1.  if said bill is not found in the set of proposed bills, raise an error
      and stop
  2.  if no election has been held for said bill, raise an error and stop
  3.  if an election has been held for said bill, but that election has not
      yet closed, raise an error and stop
  4.  if the total number of votes cast in said election is less than the
      quorum cited on the call for votes for said election, raise an error
      and stop
  5.  if the percentage of *yea* votes tallied in the results of said
      election is less than or equal to the pasing threshold cited in the
      call for votes for said election, raise an error and stop
  6.  if the person presenting the bill is not the same person that proposed
      the bill, raise an error and stop
  7.  evaluate the simple action point requirement associated with this
      process
  8.  record the presentment in the ledger of the senate
  9.  send a presentment message to the presentment service of the office of
      the Imperium
  10. record ancillary information in the activity log regarding this process

  [1]: OBJECT::[Senate].[Present]" ,
"CREATE PROCEDURE [Senate].[Present]
  @billId int
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @presentedBy int = USER_ID() ,
          @presentedOn datetime = GETUTCDATE() ,
          @electionId int ,
          @percent real ,
          @quorum int ,
          @threshold int ,
          @totalVotes int ,
          @proposedBy int ,
          @logId bigint ,
          @err nvarchar(400) ,
          @result int = -1;
  SELECT
      @electionId = c.[ElectionId] ,
      @quorum = c.[Quorum] ,
      @threshold = c.[Threshold] ,
      @totalVotes = COUNT(v.[Id])
    FROM [Senate].[CallsForVotes] c
    JOIN [Senate].[ClosedElections] e ON c.[ElectionId] = e.[Id]
    LEFT JOIN [Senate].[Votes] v ON e.[Id] = v.[ElectionId]
    WHERE [BillId] = @billId
    GROUP BY c.[ElectionId] , c.[Quorum] , c.[Threshold];
  SELECT @percent = [Percent]
    FROM [Senate].[TallyResults]( @electionId )
    WHERE [Name] = 'yea';
  SET @err =
    CASE
      WHEN @billId IS NULL
        THEN 'Parameter @billId may not be null.'
      WHEN NOT EXISTS( SELECT [Id] FROM [Senate].[Bills] WHERE [Id] = @billId )
        THEN 'No such bill exists.'
      WHEN @electionId IS NULL
        THEN 'The specified bill has no associated election and/or call for'
             + ' votes or the associated election is not yet closed.'
      WHEN @totalVotes < @quorum
        THEN 'A quorum has not been met in the associated election.'
      WHEN @percent <= @threshold
        THEN 'A passing threshold has not been met in the associated election.'
    END;

  IF @err IS NOT NULL
    THROW 50000 , @err , 1;

  SELECT @proposedBy = [ProposedBy]
    FROM [Senate].[Bills]
    WHERE [Id] = @billId;

  IF @proposedBy <> @presentedBy
    THROW 50000 , 'A bill may only be presented by its proposer.' , 1;

  EXEC @result = [Action].[Require] @@ProcID , @logId = @logId;
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
        ON CONTRACT [//Imperium/Contracts/Presentment]
        WITH ENCRYPTION = OFF;
      SEND ON CONVERSATION @handle
        MESSAGE TYPE [//Imperium/Messages/Presentment] ( @xml );
      END CONVERSATION @handle;

      EXEC [Action].[RecordActionLogBills] @logId , @billId;
    END

  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Simple Action Point Requirement for the Presentment of Bills" ,
"The [simple action point requirement][1] for [presenting][2] a bill to the
Imperitor shall be five (20) action points.

  [1]: OBJECT::[Action].[SimpleActionPointRequirements]
  [2]: OBJECT::[Senate].[Present]" ,
"INSERT [Action].[SimpleActionPointRequirements] ( [ProcId] , [Points] )
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
GRANT SELECT, REFERENCES ON OBJECT::[Senate].[Presentments] TO [Citizen];" );

EXEC [Imperium].[Enact]
    "Senatorial Presentment Procedure" ,
"To allow for bills passed in the senate to be presented to the Imperitor for
enactment into law, the Imperitor of the Imperium, Archon, does hereby
proclaim," ,
    @clauses;
DELETE @clauses
GO