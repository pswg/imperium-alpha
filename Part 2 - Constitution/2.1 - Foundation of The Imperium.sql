-- Copyright (c) Patrick Kohler
-- Licensed under the MIT License.
-- See License.txt in the project root for license information.
EXECUTE AS USER = 'Archon' WITH NO REVERT;
USE [Alpha];
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

/*******************************************************************************
 * IMPERIAL LAW 1 : Foundation of The Imperium
 * The god-king, Archon, does hereby proclaim, the founding of a great nation,
 * called The Imperium.
*******************************************************************************/

/*******************************************************************************
 * 1.1 : Foundation of The Imperium
 * There shall be a great nation, called [The Imperium][1].
 *  
 *   [1]: SCHEMA::[Imperium]
*******************************************************************************/
GO
CREATE SCHEMA [Imperium];
GO

/*******************************************************************************
 * 1.2: Office of the Imperitor
 * Complete governing authority over [The Imperium][1] shall be held by [The
 * Imperitor][2].
 *  
 *   [1]: SCHEMA::[Imperium]
 *   [2]: ROLE::[Imperitor]
*******************************************************************************/
GO
CREATE ROLE [Imperitor];
GRANT CONTROL ON SCHEMA::[Imperium] TO [Imperitor] WITH GRANT OPTION;
GO

/*******************************************************************************
 * 1.3 : Assumption of Archon
 * The first [Imperitor][1] shall be the god-king, [Archon][2].
 *  
 *   [1]: ROLE::[Imperitor]
 *   [2]: USER::[Archon]
*******************************************************************************/
GO
ALTER ROLE [Imperitor] ADD MEMBER [Archon];
GO