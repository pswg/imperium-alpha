-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER OFF;

/*******************************************************************************
 * IMPERIAL LAW 10 : The First Citizens of the Imperium
 * For the advancement and championship of Alpha and the Imperium, the
 * Imperitor of the Imperium, Archon, does hereby proclaim,
*******************************************************************************/

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "The First Citizens of Alpha" ;
SET @preamble =
"For the advancement and championship of Alpha and the Imperium, the
Imperitor of the Imperium, Archon, does hereby proclaim,";
DECLARE @clauses [Imperium].[ClauseTable]
INSERT @clauses 
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "The Fist Citizens of the Imperium" , 
"The following persons shall be [permitted entry][1] into the lands of Alpha
using a [generated password][2] and granted [citizenship][3] into the
Imperium:

  * pswg
  * djscheuf
  * H.g.Kh

  [1]: OBJECT::[Gates].[PermitEntry]
  [2]: OBJECT::[Gates].[GeneratePassword]
  [3]: ROLE::[Citizen]" , 
"DECLARE @users TABLE(
  [Name] sysname ,
  [Pwd] sysname NULL );
INSERT @users ( [Name] )
  VALUES
    ( 'pswg' ) ,
    ( 'djscheuf' ) ,
    ( 'H.g.Kh' );

DECLARE @name sysname ,
        @pwd sysname;
DECLARE [NameCursor] CURSOR LOCAL FAST_FORWARD
  FOR SELECT [Name] FROM @users

OPEN [NameCursor]
FETCH NEXT FROM [NameCursor] INTO @name
WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC [Gates].[GeneratePassword] @pwd OUTPUT;
    UPDATE @users 
    SET [Pwd] = @pwd
      WHERE [Name] = @name;
    EXEC [Gates].[PermitEntry] @name , @pwd;
    EXEC [Imperium].[GrantCitizenship] @name;
    DECLARE @sql nvarchar( 200 );
    SET @sql = CONCAT( 'ALTER ROLE [Voter] ADD MEMBER ' , QUOTENAME( @name ) );
    EXEC( @sql );
    SET @sql = CONCAT( 'ALTER ROLE [Senator] ADD MEMBER ' , QUOTENAME( @name ) );
    EXEC( @sql );
    FETCH NEXT FROM [NameCursor] INTO @name;
  END
CLOSE [NameCursor]
DEALLOCATE [NameCursor]
SELECT * FROM @users;" ) ,
    ( "Appointment of First President of the Senate" ,
"[pswg][1] shall be [inaugurated][2] as the first [President of the 
Senate][3].

  [1]: USER::[pswg]
  [2]: OBJECT::[Senate].[Inaugurate]
  [3]: ROLE::[President]" ,
"DECLARE @userId int = USER_ID( 'pswg' );
EXEC [Senate].[BeginPresidentialTerm] @userId;" );

EXEC [Imperium].[Enact] @name , @preamble , @clauses;
GO

