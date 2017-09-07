/* Use this script to insert a new Test Run to the ATF production machine.

First we insert a TestRunId row into the dbo.TestRuns table if the TestRunId does not already exist in the table.
Then we insert a TestRunID to TestSuite association in the TestRunsTestSuites table if the association does not already exist.
Lastly, we either disable or enable the TestRunId pending on the value declared in @IsDeleted
Params:
	@TestRunIDToInsert - Needs to be a unique TestRunID
	@TestSuiteIDLinkedToTestRun - The TestSuiteID you want associated to the TestRun (EX: Walmart.Brooksville Smoke Test)
	@StackVersion - The Stack Version this Test Run will represent (EX: '4.12.21')
	@IsDeleted - Set this to '0' if you want the test run is be active, '1' otherwise
*/

USE TestDatabase;

BEGIN TRAN;
BEGIN TRY
	SET IDENTITY_INSERT dbo.TestRuns OFF

	DECLARE @TestRunIDToInsert VARCHAR(2) = '1'
	DECLARE @TestSuiteIDLinkedToTestRun VARCHAR(2) = '11'
	DECLARE @StackVersion VARCHAR(8) = '4.12.25'
	DECLARE @IsDeleted VARCHAR(2) = '0'

	SET IDENTITY_INSERT dbo.TestRuns ON

	-- If the TestRunId does not exist, insert it
	IF NOT EXISTS (SELECT TestRunId FROM dbo.TestRuns WHERE TestRunId = @TestRunIdToInsert)
		BEGIN
		PRINT 'Inserting value ' + @TestRunIdToInsert + ' into TestRuns Table'
			INSERT INTO dbo.TestRuns
			(TestRunId,
			[Version],
			IsDeleted)
			VALUES
			(@TestRunIDToInsert,
			@StackVersion,
			@IsDeleted)
		END
	ELSE
		PRINT 'TestRunId already exists. Skipping insertion'

	-- Insert the assiocation of the TestRun to TestSuite
	-- If and only if there does not already exist a TestRunId and TestSuiteId pair
	IF NOT EXISTS (SELECT TestSuiteId FROM dbo.TestRunsTestSuites WHERE TestSuiteId = @TestSuiteIDLinkedToTestRun
	AND EXISTS(SELECT TestRunId FROM dbo.TestRunsTestSuites WHERE TestRunId = @TestRunIDToInsert))
		BEGIN
		PRINT 'Inserting value ' + @TestSuiteIDLinkedToTestRun + ' into TestRunsTestSuites Table'
			INSERT INTO dbo.TestRunsTestSuites
				(TestRunId,
				TestSuiteId)
			VALUES
			(@TestRunIDToInsert,
			@TestSuiteIDLinkedToTestRun)
		END
	ELSE
		BEGIN
			PRINT 'The TestRunId and TestSuiteId pair already exists in the TestRunsTestSuites Table. Skipping insertion.'
		END

	PRINT 'Updating IsDisabled value for TestRunId ' + @TestRunIdToInsert + ' to: ' + @IsDeleted
	UPDATE dbo.TestRuns
	SET IsDeleted = @IsDeleted
	WHERE TestRunId = @TestRunIDToInsert

	SET IDENTITY_INSERT dbo.TestRuns OFF

	ROLLBACK TRAN
	--COMMIT TRAN
END TRY

BEGIN CATCH
	SELECT  ERROR_LINE() ErrorLine
			,ERROR_NUMBER() ErrorNumber
			,ERROR_MESSAGE() ErrorMessage;
    
	ROLLBACK;

END CATCH;

--Show the Added TestRunId
SELECT [TestRunId],
[Version],
[IsDeleted]
FROM dbo.TestRuns

--Show what TestRunIds are associated to what TestSuiteIds
SELECT [TestRunId],
[TestSuiteId]
FROM dbo.TestRunsTestSuites