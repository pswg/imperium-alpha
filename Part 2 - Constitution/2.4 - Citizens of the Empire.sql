-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 4 : Citizens of the Empire
 * For the benefit of wellfare of the subjects of the Imperium, the Imperitor of
 * the Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Definition of Citizenship" ,
"A [citizen][1] is a recognized subject of the Imperium.

  [1]: ROLE::[Citizen]" ,
"CREATE ROLE [Citizen];" ) ,
    ( "Access to the Book of Laws" ,
"All [citizens][1] shall have the right to study the [Book of Laws][2] and to
study the [clauses][3] of laws written therein.

  [1]: ROLE::[Citizen]
  [2]: OBJECT::[Imperium].[Laws]
  [3]: OBJECT::[Imperium].[Clauses]" ,
"GRANT SELECT , REFERENCES ON OBJECT::[Imperium].[Laws] TO [Citizen];
GRANT SELECT , REFERENCES ON OBJECT::[Imperium].[Clauses] TO [Citizen];" ) ,
    ( "Access to the Book of History" ,
"All [citizens][1] shall have the right study the [Book of History][2].

  [1]: ROLE::[Citizen]
  [2]: OBJECT::[Imperium].[History]" ,
"GRANT SELECT , REFERENCES ON OBJECT::[Imperium].[History] TO [Citizen];" ) ,
    ( "Access to Clause Tables" ,
"All [citizens][1] shall have the following right to create a [clause
table][2] for any purpose.

  [1]: ROLE::[Citizen]
  [2]: TYPE::[Imperium].[ClauseTable]" ,
"GRANT EXECUTE ON TYPE::[Imperium].[ClauseTable] TO [Citizen];" ) ,
    ( "Transparency of the Imperium" ,
"All [citizens][1] shall have the right to inspect any institutions of the
[Imperium][2].

  [1]: ROLE::[Citizen]
  [2]: SCHEMA::[Imperium]" ,
"GRANT VIEW DEFINITION ON SCHEMA::[Imperium] TO [Citizen];" ) ,
    ( "The Census" ,
"A [census][1] shall be taken of the [citizens][2] of the Imperium which
shall record:

 * the identity of each citizen
 * the name by which each citizen prefers to be known
 * and the date and time of the birth of each citizen into the world of
   Alpha.

  [1]: OBJECT::[Imperium].[Census]
  [2]: ROLE::[Citizen]" ,
"CREATE FUNCTION [Imperium].[Census]()
RETURNS TABLE
AS
RETURN
  SELECT
      [principal_id] AS [CitizenId] ,
      [name] AS [Name] ,
      [create_date] AS [CreatedOn]
    FROM [sys].[database_principals]
    WHERE [type] = 'S' AND IS_ROLEMEMBER( 'Citizen' , [name] ) = 1;" ) ,
    ( "Access to the Census" ,
"All [citizens][1] have the right to view the [census][1] of the Imperium.

  [1]: ROLE::[Citizen]
  [2]: OBJECT::[Imperium].[Census]" ,
"GRANT SELECT, REFERENCES ON OBJECT::[Imperium].[Census] TO [Citizen];" ) ,
    ( "Record of Citizenship Status" ,
"A record shall be of the [citizenship status][1] of every citizen within
the Imperium, noting the date and time that citizenship was either granted
or revoked.

  [1]: OBJECT::[Imperium].[CitizenshipStatus]" ,
"CREATE TABLE [Imperium].[CitizenshipStatus](
  [Id] int NOT NULL
           PRIMARY KEY
           IDENTITY( 1 , 1 ) ,
  [CitizenID] int NOT NULL ,
  [Grant] bit NOT NULL ,
  [Date] datetime NOT NULL );" ) ,
    ( "Granting of Citizenship" ,
"To [grant citizenship][1] to a person is to perform the following
procedure:

  1. extend to that person all the rights and responsibilities of
     [citzenship][2] in the Imperium
  2. record the change in that person's [citizenship status][3]

  [1]: OBJECT::[Imperium].[GrantCitizenship]
  [2]: ROLE::[Citizen]
  [3]: OBJECT::[Imperium].[CitizenshipStatus]" ,
"CREATE PROCEDURE [Imperium].[GrantCitizenship]
  @user sysname
  WITH EXECUTE AS CALLER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @err nvarchar(400) ,
          @result int = -1;
  SET @err =
    CASE
      WHEN @user IS NULL OR USER_ID( @user ) IS NULL
        THEN 'You must specify a valid user name.'
      WHEN IS_ROLEMEMBER( 'Citizen' , @user ) = 1
        THEN 'The user ''' + @user + ''' is already a citizen.'
      ELSE NULL
    END;
  IF @err IS NOT NULL
    THROW 50000 , @err , 1;
  ELSE
    BEGIN
      EXECUTE [sys].[sp_addrolemember] [Citizen] , @user;
      INSERT [Imperium].[CitizenshipStatus]( [CitizenID] , [Grant] , [Date] )
        VALUES( USER_ID( @user ) , 1 , GETUTCDATE() );
      SET @result = 0;
    END
  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Revokation of Citizenship" ,
"To [revoke citizenship][1] from a person is to perform the following
procedure:

  1. strip that person of all the rights and responsibilities of
     [citzenship][2] in the Imperium
  2. record the change in that person's [citizenship status][3]

  [1]: OBJECT::[Imperium].[RevokeCitizenship]
  [2]: ROLE::[Citizen]
  [3]: OBJECT::[Imperium].[CitizenshipStatus]" ,
"CREATE PROCEDURE [Imperium].[RevokeCitizenship](
  @user sysname )
  WITH EXECUTE AS CALLER
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @error nvarchar(100) ,
          @result int = -1;
  SET @error =
    CASE
      WHEN @user IS NULL OR USER_ID( @user ) IS NULL
        THEN 'You must specify a valid user name.'
      WHEN IS_ROLEMEMBER( 'Citizen' , @user ) <> 1
        THEN 'The user ''' + @user + ''' is not a citizen.'
    END;
  IF @error IS NULL
    RAISERROR( @error, 16 , 1 , @user );
  ELSE
    BEGIN
      EXECUTE [sys].[sp_droprolemember] [Citizen] , @user;
      INSERT [Imperium].[CitizenshipStatus]( [CitizenID] , [Grant] , [Date] )
        VALUES( USER_ID( @user ) , 1 , GETUTCDATE() );
      SET @result = 0;
    END
  SET NOCOUNT OFF;
  RETURN @result;
END" ) ,
    ( "Definition of Registration Lists" ,
"A [registration list][1] for a given is a list of all persons that satisfy
a given role.

  [1]: OBJECT::[Imperium].[GetAllRoleMembers]" ,
"CREATE FUNCTION [Imperium].[GetAllRoleMembers]( @roleId int )
  RETURNS @results TABLE(
    [principal_id] int ,
    [name] sysname )
  WITH EXECUTE AS OWNER
AS
BEGIN
  WITH [members]( [member_principal_id] , [role_principal_id] ) 
    AS( SELECT 
            a.[member_principal_id], 
            a.[role_principal_id]
          FROM [sys].[database_role_members] a
          UNION ALL
          SELECT 
              m.[member_principal_id], 
              b.[role_principal_id]
            FROM [sys].[database_role_members] b
            JOIN [members] AS m
              ON b.[member_principal_id] = m.[role_principal_id] )
    INSERT @results( [principal_id] , [name] )
      SELECT u.[principal_id] , u.[name]
        FROM [members] m
          JOIN [sys].[database_principals] u
          ON m.[member_principal_id] = u.[principal_id]
        WHERE u.[type] = 'S'
          AND m.[role_principal_id] = @roleId;
  RETURN;
END" ) ,
    ( "Definition of Personal Profiles" ,
"The [personal profile][1] of an person is the collection of properties
and other objects which directly relate to that person.

  [1]: SCHEMA::[My]" ,
"CREATE SCHEMA [My] AUTHORIZATION [Archon];" ) ,
    ( "Access to Personal Profiles" ,
"All [citizens][1] shall have the right to view all aspects of their own
[personal profile][2].

  [1]: ROLE::[Citizen]
  [2]: SCHEMA::[My]" ,
"GRANT SELECT, EXECUTE, REFERENCES, VIEW DEFINITION
  ON SCHEMA::[My]
  TO [Citizen];" ) ,
    ( "Citizenship Status as Personal Profile" ,
"The history of a person's [citizenship status][1] shall be part of that
person's own [personal profile][2].

  [1]: ROLE::[Imperium].[CitizenshipStatus]
  [2]: SCHEMA::[My]" ,
"CREATE VIEW [My].[CitizenshipStatus]
AS
SELECT [CitizenID], [Grant], [Date]
  FROM [Imperium].[CitizenshipStatus]
  WHERE [CitizenId] = USER_ID();" );

EXEC [Imperium].[Enact]
    "Citizens of the Empire" ,
"For the benefit of wellfare of the subjects of the Imperium, the Imperitor of
the Imperium, Archon, does hereby proclaim," ,
    @clauses;
GO

