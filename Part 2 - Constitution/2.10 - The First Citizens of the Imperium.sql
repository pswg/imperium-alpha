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
 
  [1]: OBJECT::[Gates].[PermitEntry]
  [2]: OBJECT::[Gates].[GeneratePassword]
  [3]: ROLE::[Citizen]" , 
"DECLARE @users TABLE(
  [Name] sysname ,
  [Pwd] sysname NULL );
INSERT @users ( [Name] )
  VALUES
    ( 'pswg' ) ,
    ( 'djscheuf' )
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
    FETCH NEXT FROM [NameCursor] INTO @name;
  END
CLOSE [NameCursor]
DEALLOCATE [NameCursor]
SELECT * FROM @users;" );

EXEC [Imperium].[Enact] 
    "The First Citizens of Alpha" , 
"For the advancement and championship of Alpha and the Imperium, the
Imperitor of the Imperium, Archon, does hereby proclaim," ,
    @clauses;
GO

