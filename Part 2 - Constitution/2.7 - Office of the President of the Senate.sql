-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 7 : Office of the President of the Senate
 * For the regulation and protection of shared resources within the Imperium and
 * the world of Alpha, the Imperitor of the Imperium, Archon, does hereby
 * proclaim,
*******************************************************************************/

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "Office of the President of the Senate";
SET @preamble =
"For the promotion of the general welfare essential for the enjoyment by all
the people of the blessings of democracy, the Senate of the Imperium hereby
proposes,";
DECLARE @clauses [Imperium].[ClauseTable];
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Establishment of the Office of the President of the Senate" , 
"There shall be an officially recognized office of the [President of the
Senate][1].

  [1]: ROLE::[President]" , 
"CREATE ROLE [President];" ) ,
    ( "History of the Office of the President of the Senate" , 
"The Senate shall maintain a list of current and historical [presidential
terms][1] including the ID of the person that held the term and the date and
time the term started and ended.

  [1]: OBJECT::[Senate].[PresidentialTerms]" , 
"CREATE TABLE [Senate].[PresidentialTerms](
  [Id] int NOT NULL
           IDENTITY( 1 , 1 )
           PRIMARY KEY ,
  [PresidentId] int NOT NULL ,
  [TermStartedOn] datetime NOT NULL ,
  [TermEndedOn] datetime NULL );" ) ,
    ( "Beginning of a Presidential Term" , 
"To [begin a Presidential Term][1] for a given person is to perform the
following procedure:

 1. if said ID does is not provided or does not reference a person, raise an
    error and stop
 2. if said person already holds the office of the [President][2], stop
 3. grant said person the powers of Presidency
 4. insert a line in the [presidential terms][3] to reflect the beginning of
    said person's term

  [1]: OBJECT::[Senate].[BeginPresidentialTerm]
  [2]: ROLE::[President]
  [3]: OBJECT::[Presidents]" , 
"CREATE PROCEDURE [Senate].[BeginPresidentialTerm]
  @userId int ,
  @termId int = NULL OUTPUT
AS
BEGIN
  IF NOT EXISTS( SELECT * 
                   FROM [sys].[database_principals]
                   WHERE [principal_id] = @userId AND [type] = 'S' )
    THROW 50000 , 'Provided user ID does not reference a user.' , 1;

  IF( IS_ROLEMEMBER( 'President' , USER_NAME( @userId ) ) = 1 )
    RETURN 0;

  DECLARE @sql nvarchar( 200 ) = 
    CONCAT(
      'ALTER ROLE [President] ADD MEMBER ' ,
      QUOTENAME( USER_NAME( @userId ) ) );
  EXEC( @sql );

  INSERT [Senate].[PresidentialTerms]( [PresidentId] , [TermStartedOn] )
    VALUES( @userId , GETUTCDATE() );
  SET @termId = SCOPE_IDENTITY();
  RETURN 0;
END" ) ,
    ( "Ending of a Presidential Term" , 
"To [end a Presidential Term][1] for a given person is to perform the
following procedure:

 1. if said ID does is not provided or does not reference a person, raise an
    error and stop
 2. if said person does not hold the office of the [President][2], stop
 3. strip said person of the powers of Presidency
 4. update the line in the [presidential terms][3] to reflect the ending of
    said person's term

  [1]: OBJECT::[Senate].[EndPresidentialTerm]
  [2]: ROLE::[President]
  [3]: OBJECT::[Presidents]" , 
"CREATE PROCEDURE [Senate].[EndPresidentialTerm]
  @userId int
AS
BEGIN
  IF NOT EXISTS( SELECT * 
                   FROM [sys].[database_principals]
                   WHERE [principal_id] = @userId AND [type] = 'S' )
    THROW 50000 , 'Provided user ID does not reference a user.' , 1;

  IF IS_ROLEMEMBER( 'President' , USER_NAME( @userId ) ) = 1
    RETURN 0;

  DECLARE @sql nvarchar( 200 ) = 
    CONCAT(
      'ALTER ROLE [President] ADD MEMBER ' ,
      QUOTENAME( USER_NAME( @userId ) ) );
  EXEC( @sql );

  UPDATE [Senate].[PresidentialTerms]
    SET [TermEndedOn] = GETUTCDATE()
    WHERE [PresidentId] = @userId
      AND [TermEndedOn] IS NULL;
  RETURN 0;
END" );

EXEC [Imperium].[Enact] @name , @preamble , @clauses;
GO
