import XCTest
@testable import QuickRentCar

@MainActor
final class AuthViewModelValidationTests: XCTestCase {

    func testSignIn_withInvalidEmail_setsErrorMessageWithoutNetworkCall() async {
        let vm = AuthViewModel()

        await vm.signIn(email: "invalid-email", password: "password123")

        XCTAssertEqual(vm.errorMessage, "Please enter a valid email address.")
        XCTAssertFalse(vm.isLoading)
    }

    func testSignIn_withEmptyPassword_setsErrorMessage() async {
        let vm = AuthViewModel()

        await vm.signIn(email: "valid@example.com", password: "   ")

        XCTAssertEqual(vm.errorMessage, "Please enter your password.")
        XCTAssertFalse(vm.isLoading)
    }

    func testRegister_withShortPassword_setsErrorMessage() async {
        let vm = AuthViewModel()

        await vm.register(
            email: "valid@example.com",
            password: "short",
            fullName: "Kasun Perera",
            phoneNumber: "0771234567"
        )

        XCTAssertEqual(vm.errorMessage, "Password must be at least 8 characters.")
        XCTAssertFalse(vm.isLoading)
    }

    func testRegister_withEmptyFullName_setsErrorMessage() async {
        let vm = AuthViewModel()

        await vm.register(
            email: "valid@example.com",
            password: "validPassword123",
            fullName: "   ",
            phoneNumber: "0771234567"
        )

        XCTAssertEqual(vm.errorMessage, "Please enter your full name.")
        XCTAssertFalse(vm.isLoading)
    }
}
