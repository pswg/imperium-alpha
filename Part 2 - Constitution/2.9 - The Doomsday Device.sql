-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 9 : The Doomsday Device
 * To prevent the world of Alpha from growing stagnant, Imperitor of the
 * Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Creation of the Doomsday Device" ,
"A powerful device called the [doomsday][1] device shall be created.

  [1]: SCHEMA::[Doomsday]" ,
"CREATE SCHEMA [Doomsday];" ) ,
    ( "Creation of the Doomsday Device" ,
"The [doomsday device][1] shall be autonomous.

  [1]: USER::[DoomsdayDevice]
  [2]: ROLE::[Sacerdos]" ,
"CREATE USER [DoomsdayDevice] WITHOUT LOGIN;" ) ,
    ( "The Doomsday Countdown" ,
"The [doomsday countdown][1] shall be a measure inactivity within the Imperium
computed as the number of hours since the last [bill][2] proposed in the
senate and [presented][3] to the Imperitor was enacted as [law][4],
subtracted from 96.

  [1]: OBJECT::[Doomsday].[Countdown]
  [2]: OBJECT::[Senate].[Bills]
  [3]: OBJECT::[Senate].[Presentments]
  [4]: OBJECT::[Imperium].[Laws]" ,
"CREATE FUNCTION [Doomsday].[Countdown]()
  RETURNS int
AS
BEGIN
  DECLARE @result int;
  SELECT TOP (1)
      @result = 96 - DATEDIFF( HOUR , [EnactedOn] , GETUTCDATE() )
    FROM [Senate].[Bills] b
    JOIN [Senate].[Presentments] p ON b.[Id] = p.[BillId]
    JOIN [Imperium].[Laws] l ON p.[LawId] = l.[Id]
    ORDER BY l.[Id] DESC;
  RETURN @result;
END" ) ,
    ( "The Doomsday Message" ,
"The [doomsday message][1] shall indicate the person who proposed the bill
that was most recently enacted into law.

  [1]: OBJECT::[Doomsday].[Message]" ,
"CREATE FUNCTION [Doomsday].[Message]()
  RETURNS nvarchar( 1000 )
AS
BEGIN
  DECLARE @name nvarchar( 256 ) ,
          @proposedBy nvarchar( 256 ) ,
          @fmt nvarchar( 256 ) =
            'The Doomsday Device has been triggered. The last enacted bill'
            + ' was %s proposed by %s.' ,
          @result nvarchar( 1000 );
  SELECT TOP (1)
      @name = QUOTENAME( b.[Name] , '''' ) ,
      @proposedBy = QUOTENAME( USER_NAME( b.[ProposedBy] ) )
    FROM [Senate].[Bills] b
    JOIN [Senate].[Presentments] p ON b.[Id] = p.[BillId]
    JOIN [Imperium].[Laws] l ON p.[LawId] = l.[Id]
    ORDER BY l.[Id] DESC;
  EXEC [sys].[xp_sprintf] @result OUTPUT , @fmt , @name, @proposedBy;
  RETURN @result;
END" ) ,
    ( "Tick" ,
"" ,
"CREATE TABLE [Doomsday].[Tick](
  [Last] datetime PRIMARY KEY ,
  [Countdown] int );" ) ,
    ( "The Hourglass" ,
"The doomsday device shall keep an [hourglass][1] and provide a [service][2]
for turning said hourglass.

  [1]: OBJECT::[Doomsday].[Hourglass]
  [2]: SERVICE::[//Doomsday/Service/Hourglass]" ,
"CREATE QUEUE [Doomsday].[Hourglass];
GRANT SELECT , RECEIVE ON OBJECT::[Doomsday].[Hourglass] TO [DoomsdayDevice];
CREATE SERVICE [//Doomsday/Service/Hourglass] ON QUEUE [Doomsday].[Hourglass];
GRANT SEND ON SERVICE::[//Doomsday/Service/Hourglass] TO [DoomsdayDevice];" ) ,
    ( "Turning the Hourglass" ,
"To [turn the hourglass][1], the doomsday device shall perform the following
process:

  1. wait for the sand to run out of the hourglass
  2. if the doomsday clock reads less than zero, speak the doomdsday message
     into the Echo of the Sacrum
  3. turn over the hourglass with enough sand to ensure it will run out at
     the beginning of the next hour

  [1]: OBJECT::[Doomsday].[TurnHourglass]" ,
"CREATE PROCEDURE [Doomsday].[TurnHourglass]
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @mt sysname ,
          @h uniqueidentifier ,
          @now datetime ,
          @next datetime ,
          @t int;
  WAITFOR
    ( RECEIVE TOP (1)
          @mt = [message_type_name] ,
          @h = [conversation_handle]
        FROM [Doomsday].[Hourglass] ) ,
    TIMEOUT 5000;
  IF @mt IN( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' ,
              'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
    END CONVERSATION @h;
  IF @mt = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer'
    BEGIN
      IF EXISTS ( SELECT * FROM [Doomsday].[Tick] )
        UPDATE [Doomsday].[Tick]
          SET [Last] = GETUTCDATE() , [Countdown] = [Doomsday].[Countdown]();
      ELSE
        INSERT [Doomsday].[Tick]( [Last] , [Countdown] )
          VALUES( GETUTCDATE() , [Doomsday].[Countdown]() );

      DECLARE @msg nvarchar( 1000 ) = [Doomsday].[Message]();
      IF ( [Doomsday].[Countdown]() < 0 )
        EXEC [Sacrum].[Loquere] @msg;

      SET @now = GETUTCDATE();
      SET @next = DATEADD( HOUR , DATEDIFF( HOUR , 0 , @now ) + 1 , 0 );
      SET @t = DATEDIFF( SS , @now , @next );
      BEGIN CONVERSATION TIMER( @h ) TIMEOUT = @t;
    END
  SET NOCOUNT OFF;
  RETURN 0;
END" ) ,
    ( "Powers of the Doomsday Device" ,
"The [doomsday device][1] shall be [action-exempt][2], shall be a
[Sacerdos][3] of the Sacrum, and have the power to read the [doomsday
countdown][4] and [doomsday message][5] and to [turn the hourglass][6].

  [1]: USER::[DoomsdayDevice]
  [2]: ROLE::[ActionExempt]
  [2]: ROLE::[Sacerdos]
  [3]: OBJECT::[Doomsday].[Countdown]
  [4]: OBJECT::[Doomsday].[Message]
  [5]: OBJECT::[Doomsday].[TurnHourglass]" ,
"ALTER ROLE [ActionExempt] ADD MEMBER [DoomsdayDevice];
ALTER ROLE [Sacerdos] ADD MEMBER [DoomsdayDevice];
GRANT EXECUTE ON OBJECT::[Doomsday].[Countdown] TO [DoomsdayDevice];
GRANT EXECUTE ON OBJECT::[Doomsday].[Message]TO [DoomsdayDevice];
GRANT EXECUTE ON OBJECT::[Doomsday].[TurnHourglass] TO [DoomsdayDevice];" ) ,
    ( "The Purpetual Cycle of the Hourglass" ,
"When the sand runs out of the [hourglass][1], the doomsday device shall [turn
the hourglass][2].

  [1]: OBJECT::[Doomsday].[HourGlass]
  [2]: OBJECT::[Doomsday].[TurnHourglass]" ,
"ALTER QUEUE [Doomsday].[HourGlass]
  WITH STATUS = ON ,
  ACTIVATION (
    STATUS = ON ,
    PROCEDURE_NAME = [Doomsday].[TurnHourglass] ,
    MAX_QUEUE_READERS = 1 ,
    EXECUTE AS 'DoomsdayDevice' );" ) ,
    ( "First Turn of the Hourglass" ,
"Upon enactment of this law, the enactor shall fill the [hourglass][1] of the
doomsday device with enough sand to ensure it will run out at the beginning
of the next hour.

  [1]: OBJECT::[Doomsday].[HourGlass]" ,
"DECLARE @h uniqueidentifier ,
         @now datetime ,
         @next datetime ,
         @t int;
SET @now = GETUTCDATE();
SET @next = DATEADD( HOUR , DATEDIFF( HOUR , 0 , @now ) + 1 , 0 );
SET @t = DATEDIFF( SS , @now , @next );
BEGIN DIALOG CONVERSATION @h
  FROM SERVICE [//Doomsday/Service/Hourglass]
  TO SERVICE '//Doomsday/Service/Hourglass' , 'CURRENT DATABASE';
BEGIN CONVERSATION TIMER( @h ) TIMEOUT = @t;" );

EXEC [Imperium].[Enact]
    "The Doomsday Device" ,
"To prevent the world of Alpha from growing stagnant, Imperitor of the
Imperium, Archon, does hereby proclaim," ,
    @clauses;
DELETE @clauses
GO