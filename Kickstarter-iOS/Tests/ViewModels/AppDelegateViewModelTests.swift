import XCTest
import ReactiveCocoa
import Result
@testable import Kickstarter_iOS
@testable import Library
@testable import Models
@testable import Models_TestHelpers
@testable import KsApi
@testable import KsApi_TestHelpers
@testable import ReactiveExtensions_TestHelpers

final class AppDelegateViewModelTests: TestCase {
  let vm: AppDelegateViewModelType = AppDelegateViewModel()

  func testHockeyManager_StartsWhenAppLaunches() {
    XCTAssertFalse(hockeyManager.managerStarted, "Manager should not start right away.")

    vm.inputs.applicationDidFinishLaunching(launchOptions: [:])
    XCTAssertTrue(hockeyManager.managerStarted, "Manager should start when the app launches.")
    XCTAssertTrue(hockeyManager.isAutoSendingReports, "Manager sends crash reports automatically.")
  }

  func testKoala_AppLifecycle() {
    XCTAssertEqual([], trackingClient.events)

    vm.inputs.applicationDidFinishLaunching(launchOptions: [:])
    XCTAssertEqual(["App Open"], trackingClient.events)

    vm.inputs.applicationDidEnterBackground()
    XCTAssertEqual(["App Open", "App Close"], trackingClient.events)

    vm.inputs.applicationWillEnterForeground()
    XCTAssertEqual(["App Open", "App Close", "App Open"], trackingClient.events)
  }

  func testCurrentUserUpdating_NothingHappensWhenLoggedOut() {

    let updateCurrentUserInEnvironment = TestObserver<User, NoError>()
    vm.outputs.updateCurrentUserInEnvironment.observe(updateCurrentUserInEnvironment.observer)

    vm.inputs.applicationDidFinishLaunching(launchOptions: nil)
    vm.inputs.applicationWillEnterForeground()
    vm.inputs.applicationDidEnterBackground()

    updateCurrentUserInEnvironment.assertDidNotEmitValue()
  }

  func testCurrentUserUpdating_WhenLoggedIn() {

    let updateCurrentUserInEnvironment = TestObserver<User, NoError>()
    vm.outputs.updateCurrentUserInEnvironment.observe(updateCurrentUserInEnvironment.observer)

    let postNotificationName = TestObserver<String, NoError>()
    vm.outputs.postNotification.map { $0.name }.observe(postNotificationName.observer)

    let env = AccessTokenEnvelope(access_token: "deadbeef", user: UserFactory.user)
    AppEnvironment.login(env)

    vm.inputs.applicationDidFinishLaunching(launchOptions: nil)

    updateCurrentUserInEnvironment.assertValues([env.user])
    postNotificationName.assertDidNotEmitValue()

    vm.inputs.currentUserUpdatedInEnvironment()

    updateCurrentUserInEnvironment.assertValues([env.user])
    postNotificationName.assertValues([CurrentUserNotifications.userUpdated])

    vm.inputs.applicationDidEnterBackground()
    vm.inputs.applicationWillEnterForeground()

    updateCurrentUserInEnvironment.assertValues([env.user, env.user])
    postNotificationName.assertValues([CurrentUserNotifications.userUpdated])

    vm.inputs.currentUserUpdatedInEnvironment()

    updateCurrentUserInEnvironment.assertValues([env.user, env.user])
    postNotificationName.assertValues(
      [CurrentUserNotifications.userUpdated, CurrentUserNotifications.userUpdated]
    )
  }
}
