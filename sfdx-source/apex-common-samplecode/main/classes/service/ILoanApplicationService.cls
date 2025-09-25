/**
 * @description Interface for loan application service layer defining contract for application processing
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Defines service layer contract separating interface from implementation for loose coupling
 * • Enables multiple implementations (sync, async, mock) while maintaining consistent API
 * • Registered in Application.Service factory enabling dependency injection and controlled instantiation
 * • Supports testing by allowing mock service implementations during unit tests
 * • Focuses on business process orchestration rather than detailed business logic (handled by domains)
 **/

public interface ILoanApplicationService
{
	void submitApplications(Set<Id> applicationIds);
} 