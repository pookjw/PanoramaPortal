//
//  ContentView.swift
//  PanoramaPortal
//
//  Created by Jinwoo Kim on 6/2/24.
//

import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var portalPlane: ModelEntity = .init(
        mesh: .generatePlane(width: 1.0, height: 1.0), 
        materials: [PortalMaterial()]
    )
    
    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                let localFrame: Rect3D = geometry.frame(in: .local)
                let sceneFrame: BoundingBox = content.convert(localFrame, from: .local, to: .scene)
                
                //
                
                let worldEntity: Entity = .init()
                worldEntity.components.set(WorldComponent())
                
                //
                
                let imageURL: URL! = Bundle.main.url(forResource: "image", withExtension: UTType.heic.preferredFilenameExtension)
                let image: UIImage! = .init(contentsOfFile: imageURL.path)
                let resizedImage: UIImage! = await image
                    .byPreparingThumbnail(
                        ofSize: .init(
                            width: 4000.0, 
                            height: 4000.0 * (image.size.height / image.size.width)
                        )
                    )
                
                let texture: TextureResource = try! await .generate(from: resizedImage.cgImage!, options: .init(semantic: .hdrColor))
                
                let planeEntity = try! await Entity(contentsOf: Bundle.main.url(forResource: "untitled", withExtension: "usdc")!)
                
                if let rootEntity: Entity = planeEntity.children.first(where: { $0.name == "root" }),
                   let planeEntity: Entity = rootEntity.children.first(where: { $0.name == "Plane" }),
                   let plane_001Entity: ModelEntity = planeEntity.children.first(where: { $0.name == "Plane_001" }) as? ModelEntity
                {
                    var material: UnlitMaterial = .init()
                    material.color = .init(tint: .white, texture: .init(texture))
                    material.triangleFillMode = .fill
                    
                    plane_001Entity.model?.materials = [material]
                }
                
                planeEntity.transform.rotation = .init(angle: .pi * -0.5, axis: .init(x: 0, y: 1, z: 0))
                
                planeEntity.transform.scale = .init(x: 0.5 * Float(texture.width / texture.height), y: 0.5, z: 0.5)
                planeEntity.position.z = sceneFrame.center.z - 0.2
                planeEntity.components.set(_PlaneEntityComponent())
                
                worldEntity.addChild(planeEntity)
                
                //
                
                portalPlane.addChild(worldEntity)
                portalPlane.components.set(PortalComponent(target: worldEntity))
                
                content.add(portalPlane)
            } update: { content in
                let localFrame: Rect3D = geometry.frame(in: .local)
                let sceneFrame: BoundingBox = content.convert(localFrame, from: .local, to: .scene)
                let size = content.convert(geometry.size, from: .local, to: .scene)
                
                portalPlane.model?.mesh = .generatePlane(
                    width: size.x,
                    height: size.y,
                    cornerRadius: 0.1
                )
                
                portalPlane
                    .children
                    .filter { $0.components.has(_PlaneEntityComponent.self) }
                    .forEach { $0.position.z = sceneFrame.center.z - 0.15 }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}

fileprivate struct _PlaneEntityComponent: Component {
    
}
