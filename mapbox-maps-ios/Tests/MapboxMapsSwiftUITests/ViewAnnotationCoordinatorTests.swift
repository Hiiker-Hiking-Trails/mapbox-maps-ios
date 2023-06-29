@_spi(Experimental) @testable import MapboxMapsSwiftUI
@_spi(Package) import MapboxMaps
import CoreLocation
import XCTest
import SwiftUI

@available(iOS 13.0, *)
final class ViewAnnotationCoordinatorTests: XCTestCase {
    var me: ViewAnnotationCoordinator!
    var viewAnnotationsManager: MockViewAnnotationsManager!

    override func setUpWithError() throws {
        me = ViewAnnotationCoordinator()
        viewAnnotationsManager = MockViewAnnotationsManager()
    }

    override func tearDownWithError() throws {
        viewAnnotationsManager = nil
        me = nil
    }

    func testUpdateAnnotations() throws {
        func verifyAnnotationOptions(_ options: ViewAnnotationOptions?, _ config: ViewAnnotationConfig) {
            XCTAssertEqual(options?.geometry, .point(config.point))
            XCTAssertEqual(options?.allowOverlap, config.allowOverlap)
            XCTAssertEqual(options?.anchor, config.anchor)
            XCTAssertEqual(options?.offsetX, config.offsetX)
            XCTAssertEqual(options?.offsetY, config.offsetY)
        }

        var numberOfViewsAdded = 0
        me.setup(with: ViewAnnotationCoordinator.Deps(
            viewAnnotationsManager: viewAnnotationsManager,
            addViewController: { _ in
                numberOfViewsAdded += 1
            }, removeViewController: { _ in
                numberOfViewsAdded -= 1
            }))

        let options = (0...4).map { _ in ViewAnnotation<EmptyView>.random() }
        var annotations = [AnyHashable: ViewAnnotation<EmptyView>]()
        annotations[0] = options[0]

        me.updateAnnotations(to: annotations)

        XCTAssertEqual(numberOfViewsAdded, 1, "added total 1 annotation view")
        XCTAssertEqual(viewAnnotationsManager.addViewStub.invocations.count, 1)
        let opt0Invocation = try XCTUnwrap(viewAnnotationsManager.addViewStub.invocations.last)
        verifyAnnotationOptions(opt0Invocation.parameters.options, options[0].config)
        let option0InternalView = opt0Invocation.parameters.view

        annotations[1] = options[1]
        annotations[2] = options[2]
        me.updateAnnotations(to: annotations)

        XCTAssertEqual(numberOfViewsAdded, 3, "added total 2 annotation views")
        XCTAssertEqual(viewAnnotationsManager.addViewStub.invocations.count, 3, "added 2 annotations")
        XCTAssertEqual(viewAnnotationsManager.updateViewStub.invocations.count, 0, "no updates")
        XCTAssertEqual(viewAnnotationsManager.removeViewStub.invocations.count, 0, "no removals")

        me.updateAnnotations(to: annotations)

        XCTAssertEqual(numberOfViewsAdded, 3, "no additions")
        XCTAssertEqual(viewAnnotationsManager.addViewStub.invocations.count, 3, "no additions")
        XCTAssertEqual(viewAnnotationsManager.updateViewStub.invocations.count, 0, "no updates")
        XCTAssertEqual(viewAnnotationsManager.removeViewStub.invocations.count, 0, "no removals")

        annotations[3] = options[3]
        me.updateAnnotations(to: annotations)

        XCTAssertEqual(numberOfViewsAdded, 4, "added total 4 annotation views")
        XCTAssertEqual(viewAnnotationsManager.addViewStub.invocations.count, 4)
        let opt3Invocation = try XCTUnwrap(viewAnnotationsManager.addViewStub.invocations.last)
        verifyAnnotationOptions(opt3Invocation.parameters.options, options[3].config)
        let option3InternalView = opt3Invocation.parameters.view

        annotations.removeValue(forKey: 3)
        annotations.removeValue(forKey: 0)
        annotations[1] = options[4]
        me.updateAnnotations(to: annotations)

        XCTAssertEqual(numberOfViewsAdded, 2)
        XCTAssertEqual(viewAnnotationsManager.addViewStub.invocations.count, 4, "nothing added")
        verifyAnnotationOptions(viewAnnotationsManager.updateViewStub.invocations.last?.parameters.options, options[4].config)
        let removedViews = Set(viewAnnotationsManager.removeViewStub.invocations.map(\.parameters))
        XCTAssertEqual(removedViews, Set([option0InternalView, option3InternalView]))
    }
}

@available(iOS 13.0, *)
extension ViewAnnotation where Content == EmptyView {

    static func random() -> ViewAnnotation<Content> {
        ViewAnnotation(
            CLLocationCoordinate2D.random(),
            allowOverlap: .random(),
            offsetX: .random(in: 0...100),
            offsetY: .random(in: 0...100)
        ) {}
    }
}
