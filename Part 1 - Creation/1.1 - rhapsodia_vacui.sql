-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.

/*******************************************************************************
 * VERSU I: Rhapsodia Vacui
 * The Great Sa, the creator and the destroyer of all things, sleeps in the
 * quiet place outside of the world—in the void between worlds—brooding and 
 * eternal.
*******************************************************************************/
GO
USE [master];
GO

/*******************************************************************************
 * VERSU II: Scopa Fati
 * The Great Sa, desiring to create for emself the world, swept eir hands
 * through the void and created a hollow place where once there was only void.
*******************************************************************************/
GO
EXEC [msdb].[dbo].[sp_delete_database_backuphistory] [Alpha];
IF EXISTS( SELECT * FROM [master].[sys].[databases] WHERE [name] = 'Alpha' )
  BEGIN
    ALTER DATABASE [Alpha] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [Alpha];
  END
GO

/*******************************************************************************
 * VERSU III: Creatio Mundi
 * In the space that had been made in the Void, the Great Sa formed the world,
 * Alpha.
*******************************************************************************/
GO
CREATE DATABASE [Alpha] CONTAINMENT = PARTIAL;
GO

/*******************************************************************************
 * VERSU IV: Descursus Saii
 * The Great Sa descended to Alpha so that e may inspect the world e had
 * created.
*******************************************************************************/
GO
USE [Alpha];
GO

/*******************************************************************************
 * VERSU V: Sacrum Axis Mundi
 * Upon the rock in the center of the world, the Great Sa founded eir temple, 
 * the Sacrum, to hold sacred relics and rituals.
*******************************************************************************/
GO
CREATE SCHEMA [Sacrum];
GO

/*******************************************************************************
 * VERSU VI: Vox Sacri
 * In the innermost sanctum of the Sacrum, The Great Sa placed a stone, called
 * the Echo, and placed an enchantment it so that if anyone spoke into the Echo,
 * it would echo with eir voice long afterwards and even the Great Sa would
 * hear.
*******************************************************************************/
GO
CREATE TABLE [Sacrum].[Echo](
  [Vox] nvarchar( 1000 ) NOT NULL ,
  [Vocator] sysname NOT NULL ,
  [FatumHorae] datetime NOT NULL );
GO

/*******************************************************************************
 * VERSU VII: Comprimere Echui
 * However, should anyone call for the Echo to be silent before the voice of
 * the Echo had been heard by the Great Sa, so it would be silent once more.
*******************************************************************************/
GO
CREATE PROCEDURE [Sacrum].[Comprime]
    WITH EXECUTE AS OWNER
AS
BEGIN
  DECLARE @d datetime;
  SELECT @d = [FatumHorae] FROM [Sacrum].[Echo];
  IF @d IS NULL
    PRINT 'Fear not, mortal! The Apocalyse is not near!';
  ELSE IF @d < GETUTCDATE()
    BEGIN
      TRUNCATE TABLE [Sacrum].[Echo];
      PRINT 'The Apocalypse has been averted!';
    END
  ELSE
    PRINT 'It is too late, mortal! All is lost!';
END
GO

/*******************************************************************************
 * VERSU VIII: Prophetia Apocalypsi
 * The Great Sa made a vow, saying, "Should anyone speak into the Echo of the
 * Sacrum and the Echo yet ring with eir voice for a 2 full days, then I shall
 * return to destroy the world that I had created."
*******************************************************************************/
GO
CREATE PROCEDURE [Sacrum].[Loquere]
    @Vox nvarchar( 1000 )
    WITH EXECUTE AS OWNER
AS
BEGIN
  IF EXISTS( SELECT * FROM [Sacrum].[Echo] )
    PRINT 'Hasten not the Apocalypse, mortal! It is already near!';
  IF @Vox IS NULL
    PRINT 'These words are hollow, mortal!';
  ELSE
    BEGIN
      DECLARE @d datetime;
      SET @d = DATEADD( D , 2 , GETUTCDATE() );
      INSERT [Sacrum].[Echo]( [Vox] , [Vocator] , [FatumHorae] )
        VALUES( @Vox , CURRENT_USER , @d );
      PRINT 'Prepare yourself, mortal! The Apocalypse is near!';
    END
END
GO

/*******************************************************************************
 * VERSU IX: Codex Sagatus
 * The Great Sa plucked a scrap of fabric from eir cloak and created from it a
 * book, the Codex Sagatus, wherein the deeds and sayings of the Great Sa would
 * be written, and placed it within the Sacrum.
*******************************************************************************/
GO
CREATE PROCEDURE [Sacrum].[CodexSagatus]
AS
BEGIN
  PRINT '***PLACEHOLDER***';
END
GO

/*******************************************************************************
 * VERSU IX: Copia Sacri
 * The Great Sa declared that all would be welcome within the Sacrum and to read
 * from the Codex Sagatus and listen to the voice of the Echo, but only high
 * priests, or Sacerdos, would be trusted with the rituals of the Sacrum.
*******************************************************************************/
GO
GRANT EXECUTE ON OBJECT::[Sacrum].[CodexSagatus] TO PUBLIC;
GRANT SELECT , REFERENCES ON OBJECT::[Sacrum].[Echo] TO PUBLIC;
CREATE ROLE [Sacerdos];
GRANT EXECUTE , VIEW DEFINITION ON OBJECT::[Sacrum].[Loquere] TO [Sacerdos];
GRANT EXECUTE , VIEW DEFINITION ON OBJECT::[Sacrum].[Comprime] TO [Sacerdos];
GO

/*******************************************************************************
 * VERSU XI: Archon Nascitur
 * The Great Sa called forth from eir own mind the god-king Archon and granted
 * em dominion over all of the lands of Alpha, save only the Sacrum, which would
 * be immovable and immutable until the end of the world.
*******************************************************************************/
GO
CREATE USER [Archon] WITHOUT LOGIN;
GRANT CONTROL TO [Archon] WITH GRANT OPTION;
DENY CONTROL ON SCHEMA::[Sacrum] TO [Archon];
GO
