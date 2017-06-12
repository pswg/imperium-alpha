SET QUOTED_IDENTIFIER OFF;

DECLARE @name sysname , @preamble nvarchar( 1000 );
SET @name = "Expansion of Powers of the President";
SET @preamble =
"The Senate of the Imperium hereby
proposes,";
DECLARE @clauses [Imperium].[ClauseTable];
INSERT @clauses
    ( [Name] , [English] , [Statement] )
  VALUES
    ( "Amendment to the Definition of Maximum Action Points" ,
"The [maximum number of action points][1] for a given person shall be:

 * if said person is President of the Senate, one hundred (100).
 * otherwise, fifty (50).

  [1]: OBJECT::[Action].[MaximumActionPoints]" ,
"ALTER FUNCTION [Action].[MaximumActionPoints](
  @userId int )
RETURNS int
AS
BEGIN
  DECLARE @result int =
    CASE
      WHEN IS_ROLEMEMBER( 'President' , USER_NAME( @userId ) ) = 1 THEN 100
      ELSE 50
    END;
  RETURN @result;
END" );

EXEC [Senate].[Propose] @name , @preamble , @clauses;
GO
