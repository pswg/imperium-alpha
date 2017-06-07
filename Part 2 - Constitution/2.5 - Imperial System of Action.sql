-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 5 : Imperial System of Action
 * For the regulation and protection of shared resources within the Imperium and
 * the world of Alpha, the Imperitor of the Imperium, Archon, does hereby
 * proclaim,
*******************************************************************************/

DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Establishment of the Imperial System of Action" ,
"There shall be a regulated collection of objects, named as the [imperial
system of action][1].

  [1]: SCHEMA::[Action]" ,
"CREATE SCHEMA [Action];" ) ,
    ( "Definition of Action Points" ,
"A ledger of [action points][1], which hereafter may be abreviated as **AP**,
shall be kept and shall include:

  1. the identity of the person which owns the action points
  2. the number of action points that person currently possesses
  3. the date and time the person that the indivual last earned gained an
     action point, which hereafter may be referred to as the person's
     recovery timer

  [1]: OBJECT::[Action].[ActionPoints]" ,
"CREATE TABLE [Action].[ActionPoints](
    [UserId] int NOT NULL
                 PRIMARY KEY ,
    [Value] int NOT NULL ,
    [Timer] datetime NOT NULL );" ) ,
    ( "Definition of Action Log" ,
"A [log of actions][1] shall be kept, recording the certain activities of
persons. Each line in the action log shall include:

  1. a unique numerical identifier
  2. the identity of the person that the line regards
  3. the number of action points gained or lost by the person
  4. the date and time the line was recorded in the action log

  [1]: OBJECT::[Action].[ActionLog]" ,
"CREATE TABLE [Action].[ActionLog](
  [Id] bigint NOT NULL
              IDENTITY( 1 , 1 )
              PRIMARY KEY ,
  [UserId] int NOT NULL ,
  [Change] int NOT NULL ,
  [Process] int NOT NULL ,
  [Date] datetime NOT NULL );" ) ,
    ( "Definition of tMaximum Action Points" ,
"The [maximum number of action points][1] any indivudal may have shall be
twenty (20).

  [1]: OBJECT::[Action].[MaximumActionPoints]" ,
"CREATE FUNCTION [Action].[MaximumActionPoints](
  @userId sysname )
RETURNS int
AS
BEGIN
  RETURN 20;
END" ) ,
    ( "Recovery Rate" ,
"The number of seconds required for any person to recover a single action
point, which hereafter may be referred to as the [recovery rate][1], shall be
sixty (60).

  [1]: OBJECT::[Action].[RecoveryRate]" ,
"CREATE FUNCTION [Action].[RecoveryRate](
  @userId sysname )
RETURNS int
AS
BEGIN
  RETURN 60;
END" ) ,
    ( "Definition of Action-Exemption" ,
"There shall be a set of persons which shall not be limited by action point
requirements, which hereafter may be referred to as [action-exempt][1].

  [1]: ROLE::[ActionExempt]" ,
"CREATE ROLE [ActionExempt];" ) ,
    ( "Imperitor Exemption" ,
"The [imperitor][1] shall be [action-exempt][2].

  [1]: ROLE::[Imperitor]
  [2]: ROLE::[ActionExempt]" ,
"ALTER ROLE [ActionExempt] ADD MEMBER [Imperitor];" ) ,
    ( "Recovering Action Points (I)" ,
"To [recover action points for a specified person][1] is to perform the
following process:

  1. if the person is [action-exempt][2], stop
  2. if the person has not previously recovered [action points][3]
    1. set the number of action points the person currently owns as zero (0)
    2. set the value of the person's recovery timer to current date and time
    3. stop
  3. compute the number of recovered action points as the smaller of
    * the number of seconds betwen the current date and time and the value of
      the person's recovery timer divided by the person's [recovery rate][4],
      rounded down to the nearest whole number
    * the person's [maximum number of action points][5] the person may have
      minus the person's current number of action points
  4. if the number of recovered action points is less than or equal to zero
     (0), stop
  5. increase the number of action points the person currently owns by the
     number of recovered action points
  6. increase the value of the person's recovery timer by a number of seconds
     equal to the number of recovered action points multiplied by the
     person's recovery rate
  7. if the last line in the [action log][6] for the person is a reference to
     the [action point recovery][7] process
    1. increase the number of action points in the last line in action log
       for the person line by the number of recovered action points
    2. increase the date that the action log was recorded to the current date
       and time
  8. if the last line in the action log for the person is not a reference to
     the process of recovering action points
    1. write a new line in the action log noting the identity of the person,
       the number of recovered action points, and identity of the action
       point recovery process, and the current date and time.
    2. the numeric identifier of the newly written log line shall be
       returned to the caller
  9. the number of recovered action points shall be returned to the caller

  [1]: OBJECT::[Action].[RecoverFor]
  [2]: ROLE::[ActionExempt]
  [3]: OBJECT::[Action].[ActionPoints]
  [4]: OBJECT::[Action].[RecoveryRate]
  [5]: OBJECT::[Action].[MaximumActionPoints]
  [6]: OBJECT::[Action].[ActionLog]
  [7]: OBJECT::[Action].[Recover]" ,
"CREATE PROCEDURE [Action].[RecoverFor]
  @userId int ,
  @points int = NULL OUTPUT ,
  @logId bigint = NULL OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @timer datetime = GETUTCDATE() ,
          @prevTimer datetime ,
          @curAP int ,
          @maxAP int ,
          @newAP int ,
          @totalAP int ,
          @rate int ,
          @procId int = OBJECT_ID( '[Action].[Recover]' );
  SET @points = 0;

  IF IS_ROLEMEMBER( 'ActionExempt', USER_NAME(@userId) ) = 1
    RETURN 0;
  IF NOT EXISTS( SELECT *
                   FROM [Action].[ActionPoints]
                   WHERE [UserId] = @userId )
    BEGIN
      INSERT [Action].[ActionPoints]( [UserId] , [Value] , [Timer] )
        VALUES( @userId , 0 , @timer );
      RETURN 0;
    END

  SELECT
      @prevTimer = [Timer] ,
      @curAP = [Value] ,
      @maxAP = [Action].[MaximumActionPoints]( @userId ) ,
      @rate = [Action].[RecoveryRate]( @userId )
    FROM [Action].[ActionPoints]
    WHERE [UserId] = @userId;

  SET @newAP = DATEDIFF( SECOND , @prevTimer , @timer ) / @rate;
  SET @totalAP = @newAP + @curAP;
  SET @points = IIF( @totalAP > @maxAP , @maxAP , @totalAP ) - @curAP;
  SET @timer = DATEADD( SECOND , @rate * @points , @prevTimer );

  IF @points <= 0
    RETURN 0;

  UPDATE [Action].[ActionPoints]
    SET
      [Value] += @points ,
      [Timer] = @timer
    WHERE [UserId] = @userId;

  WITH [Log]
    AS( SELECT TOP (1)
            [Id] ,
            [Change] ,
            [Process] ,
            [Date]
          FROM [Action].[ActionLog]
          WHERE [UserId] = @userId
          ORDER BY [Date] DESC )
    UPDATE [Log]
      SET
        [Change] += @points ,
        [Date] = GETUTCDATE() ,
        @logId = [Id]
      WHERE [Process] = @procId;
  IF @@ROWCOUNT = 0
    BEGIN
      INSERT [Action].[ActionLog]( [UserId] , [Change] , [Process] , [Date] )
        VALUES( @userId , @points , @procId , GETUTCDATE() );
      SET @logId = SCOPE_IDENTITY();
    END

  SET NOCOUNT OFF;
  RETURN 0;
END" ) ,
    ( "Recovering Action Points (II)" ,
"To [recover action points][1] is to [recover action points for oneself][2].

  [1]: OBJECT::[Action].[Recover]
  [2]: OBJECT::[Action].[RecoverFor]" ,
"CREATE PROCEDURE [Action].[Recover]
AS
BEGIN
  DECLARE @userId int = USER_ID() ,
          @points int;
  EXEC [Action].[RecoverFor] @userId , @points = @points OUTPUT;

  PRINT 'You have recovered ' + CAST( @points AS NVARCHAR(30) ) + ' AP.';
END" ) ,
    ( "Definition of a Simple Action Point Requirements" ,
"A [simple action point requirement][1], which hereafter may be referred to as
a simple requirement, for a procedure is an a non-negative number of action
points assocated with that procedure.

  [1]: OBJECT::[Action].[SimpleActionPointRequirements]" ,
"CREATE TABLE [Action].[SimpleActionPointRequirements](
  [ProcId] int NOT NULL
           PRIMARY KEY ,
  [Points] int NOT NULL ,
  CONSTRAINT [CK_Points]
    CHECK ( [Points] >= 0 ));" ) ,
    ( "Requiring Action Points" ,
"To [require][1] a given non-negative number of [action points][2], from a
given person, to perform a given procedure, is to perform the following
procedure:

  1. if the specified number of action points is negative, raise an error and
     stop
  2. if the specified procedure identifier does not identify a valid
     procedure, raise an error and stop
  3. if the person is [action-exempt][3], stop
  4. if the number of action points is not specified, or if specified number
     of action points is equal to the `NULL` value the value of the [simple
     action point requirement][4] for the procedure shall be used in place of
     the specified number of action points
  5. recover action for the person
  6. if the number of action points the person currently has is less than
     specified number of action points, raise an error and stop
  7. if the specified number of action points is greater than zero
    1. reduce the number of action points the person currently has by the
       specified number of action points
    2. if the number of action points the person has prior to the reduction
       is greater than or equal to the maximum number of action points the
       person may have *and* the number of action points the person has after
       the reduction is less than the maximum number of action points the
       person may have, set the value of the person's reset timer to the
       current date and time
  8. write a new line in the [action log][5] noting the identity of the
     person, the number of recovered action points, and identity of the
     procedure which the requirement was evaluated, and the current date and
     time.

  [1]: OBJECT::[Action].[Require]
  [2]: OBJECT::[Action].[ActionPoints]
  [3]: ROLE::[ActionExempt]
  [4]: OBJECT::[Action].[SimpleActionPointRequirements]
  [5]: OBJECT::[Action].[ActionLog]" ,
"CREATE PROCEDURE [Action].[Require]
    @procId int ,
    @points int = NULL ,
    @userId int = NULL ,
    @logId bigint = NULL OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @err nvarchar( 400 );

  IF @points < 0
    THROW 50000 , N'Parameter @points must be non-negative.' , 1;
  IF NOT EXISTS( SELECT *
                   FROM [sys].[procedures]
                   WHERE [object_id] = @procId )
    BEGIN
      SET @err =
        'No procedure with ID '
        + CAST( @procId AS nvarchar( 30 ) )
        + ' exists.';
      THROW 50000 , @err , 1;
    END

  IF @points IS NULL
    SELECT @points = [Points]
      FROM [Action].[SimpleActionPointRequirements]
      WHERE [ProcId] = @procId;
  SET @points = ISNULL( @points , 0 );
  SET @userId = ISNULL( @userId , USER_ID() );
  DECLARE @value int ,
          @maxAP int ,
          @return int = -1;

  IF USER_NAME(@userId) IS NULL
    THROW 50000 , N'Specified user does not exist.' , 1;
  ELSE IF IS_ROLEMEMBER( 'ActionExempt', USER_NAME( @userId ) ) = 1
    RETURN 0;

  EXEC [Action].[RecoverFor] @userId;

  SELECT
      @value = [Value] ,
      @maxAP = [Action].[MaximumActionPoints]( @userId )
    FROM [Action].[ActionPoints]
    WHERE [UserId] = @userId;

  IF ISNULL( @value , 0 ) < @points
    BEGIN
      SET @err =
        'This action requres at least '
        + CAST( @points AS nvarchar(30) )
        + ' AP. Use [Recover] to gain AP.';
      THROW 50000 , @err , 1;
    END
  ELSE IF @points > 0
    UPDATE [Action].[ActionPoints]
      SET
        [Value] -= @points ,
        [Timer] =
          IIF(
            @value >= @maxAP AND ( @value - @points ) < @maxAP ,
            GETUTCDATE() ,
            [Timer] )
      WHERE [UserId] = @userId;

  INSERT [Action].[ActionLog] ( [UserId] , [Change] , [Process] , [Date] )
    VALUES( @userId , -@points , @procId , GETUTCDATE() );

  SET @logId = SCOPE_IDENTITY();
  SET @return = 0;

  SET NOCOUNT OFF;
  RETURN @return;
END" ) ,
    ( "Action Points as Personal Profile Component" ,
"The current status of an person's [action points][1] shall be a component of
that person's [personal profile][2].

  [1]: ROLE::[Action].[ActionPoints]
  [2]: SCHEMA::[My]" ,
"CREATE VIEW [My].[ActionPoints]
AS
SELECT
    [UserId] ,
    [Value] ,
    [Timer]
  FROM [Action].[ActionPoints]
  WHERE [UserId] = USER_ID();" ) ,
    ( "Action Log Information as Profile Component" ,
"The history of a person's [action][1] shall be a [component][2] of that
person's [personal profile][3].

  [1]: ROLE::[Action].[ActionLog]
  [2]: OBJECT::[My].[ActionLog]
  [3]: SCHEMA::[My]" ,
"CREATE VIEW [My].[ActionLog]
AS
SELECT
    [Id] ,
    [UserId] ,
    [Change] ,
    [Process] ,
    [Date]
  FROM [Action].[ActionLog]
  WHERE [UserID] = USER_ID();" ) ,
    ( "Access to Action Point Recovery" ,
"All [citizens][1] may [recover eir own action points][2].

  [1]: ROLE::[Citizen]
  [2]: OBJECT::[Action].[Recover]" ,
"GRANT EXECUTE ON OBJECT::[Action].[Recover] TO [Citizen];" ) ,
    ( "Access to Information Regarding Simple Action Requirements" ,
"All [citizens][1] may [view the simple action point requirement][2] of any
procedure.

  [1]: ROLE::[Citizen]
  [2]: OBJECT::[Action].[SimpleActionPointRequirements]" ,
"GRANT SELECT
  ON OBJECT::[Action].[SimpleActionPointRequirements]
  TO [Citizen];" );

EXEC [Imperium].[Enact]
    "Imperial System of Action" ,
"For the regulation and protection of shared resources within the Imperium and
the world of Alpha, the Imperitor of the Imperium, Archon, does hereby
proclaim," ,
    @clauses;
GO
