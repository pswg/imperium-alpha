-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 3 : Gates of Alpha
 * For the protection of the lands and peoples of Alpha, the Imperitor of the
 * Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses 
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "The Gates of Alpha" , 
"Access to the world of Alpha shall be controlled by the [Gates of Alpha][1].
 
  [1]: SCHEMA::[Gates]" , 
"CREATE SCHEMA [Gates];" ) , 
    ( "Permission of Entry" , 
"An person may be [permitted entry][1] to the world of Alpha by declaring a
unique name and a password. That person will then have the power to modify eir
password after e enters Alpha.
 
  [1]: OBJECT::[Gates].[PermitEntry]" , 
"CREATE PROCEDURE [Gates].[PermitEntry]
  @name sysname ,
  @password nvarchar( 128 )
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @qName nvarchar( 1000 ) = QUOTENAME( @name ) ,
          @qPass nvarchar( 1000 ) = QUOTENAME( @password, '''' ) ,
          @sql nvarchar( 4000 );
  SET @sql = 'CREATE USER ' + @qName + ' WITH PASSWORD = ' + @qPass + ';';
  EXEC ( @sql );
  SET @sql = 'GRANT ALTER ON USER::' + @qName + ' TO ' + @qName + ';';
  EXEC ( @sql );
END" ) , 
    ( "Barrier of Entry" , 
"An person may be [barred entry][1], either temporarily or permanently.
 
  [1]: OBJECT::[Gates].[BarEntry]" , 
"CREATE PROCEDURE [Gates].[BarEntry]
  @name sysname ,
  @permanent bit = 0
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @qName nvarchar( 1000 ) = QUOTENAME( @name ) ,
          @sql nvarchar( 4000 );
  SET @sql = 
    IIF(
      @permanent = 0 ,
      'REVOKE CONNECT FROM ' + @qName + ';' ,
      'DROP USER ' + @qName + ';' );
  EXEC ( @sql );
END" ) , 
    ( "Lifting of Barrier of Entry" , 
"An person that has temporarily been barred entry may have that [barrier
lifted][1].
 
  [1]: OBJECT::[Gates].[LiftBarrier]" , 
"CREATE PROCEDURE [Gates].[LiftBarrier]
  @name sysname
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @qName nvarchar( 1000 ) = QUOTENAME( @name ) ,
          @sql nvarchar( 4000 );
  SET @sql = 
    'GRANT CONNECT TO ' + @qName + ';';
  EXEC ( @sql );
END" ) , 
    ( "Secure Password Generation" , 
"To maintain security and protect the identity of persons in the world of
Alpha [secure password may be generated][1] on request.
 
  [1]: OBJECT::[Gates].[GeneratePassword]" , 
"CREATE PROCEDURE [Gates].[GeneratePassword]
  @password nvarchar( 20 ) OUTPUT
  WITH EXECUTE AS CALLER
AS
BEGIN
  DECLARE @bin VARBINARY( 15 ) = CRYPT_GEN_RANDOM( 15 );
  SET @password =
    CAST( '' AS xml ).value(
      'xs:base64Binary(sql:variable(""@bin""))' ,
      'nvarchar( 30 )' );
  SELECT
      @password = REPLACE( @password , [a] , [b] )
    FROM (
      VALUES
        ( '/' , '_' ) ,
        ( '0' , '^' ) ,
        ( 'O' , '%' ) ,
        ( '1' , '#' ) ,
        ( 'l' , '&' )
    ) [t]( [a] , [b] );
END" );

EXEC [Imperium].[Enact] 
    "Gates of Alpha" , 
"For the protection of the lands and peoples of Alpha, the Imperitor of the
Imperium, Archon, does hereby proclaim," , 
    @clauses;
GO

