//
//  ContentView.swift
//  Hand Detection
//
//  Created by Wei Liu on 2021/02/09.
//

import SwiftUI

import Foundation
import AVKit

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CALayerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    var caLayer: CALayer

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.layer.addSublayer(caLayer)
        caLayer.frame = viewController.view.layer.frame
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        caLayer.frame = uiViewController.view.layer.frame
    }
}

struct SimpleVideoCaptureView: View {
    @ObservedObject
    var presenter: SimpleVideoCapturePresenter
    var body: some View {
        ZStack {
            CALayerView(caLayer: presenter.previewLayer)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            self.presenter.apply(inputs: .onAppear)
        }
        .onDisappear {
            self.presenter.apply(inputs: .onDisappear)
        }
    }
}

class SimpleVideoCapturePresenter: ObservableObject {

    var previewLayer: CALayer {
        return interactor.previewLayer!
    }

    enum Inputs {
        case onAppear
        case tappedCameraButton
        case onDisappear
    }

    init() {
        interactor.setupAVCaptureSession()
    }

    func apply(inputs: Inputs) {
        switch inputs {
            case .onAppear:
                interactor.startSession()
            break
            case .tappedCameraButton:
            break
            case .onDisappear:
              interactor.stopSession()
        }
    }

    // MARK: Privates
    private let interactor = SimpleVideoCaptureInteractor()
}
