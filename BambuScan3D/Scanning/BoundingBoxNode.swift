import SceneKit
import simd

/// Gerçek dünyada masaya sabitlenen, telefon nereye dönerse dönsün yerini koruyan 3D Tarama Kutusu
public final class BoundingBoxNode: SCNNode {
    
    private let boxWireframeNode = SCNNode()
    private let baseRingNode = SCNNode()
    
    public override init() {
        super.init()
        setupNodes()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNodes()
    }
    
    private func setupNodes() {
        addChildNode(boxWireframeNode)
        addChildNode(baseRingNode)
    }
    
    /// Kutuyu dünya koordinatlarında belirtilen konuma ve boyuta günceller
    public func update(center: SIMD3<Float>, size: SIMD3<Float>, isScanning: Bool) {
        // Gerçek dünya konumu
        self.simdPosition = center
        
        // 1. 3D Tel Çerçeve ve Yarı Saydam Kutu
        let boxGeo = SCNBox(
            width: CGFloat(size.x),
            height: CGFloat(size.y),
            length: CGFloat(size.z),
            chamferRadius: 0.003
        )
        
        // Kenar Çizgileri
        let lineMat = SCNMaterial()
        lineMat.fillMode = .lines
        lineMat.diffuse.contents = isScanning ? UIColor(red: 0.0, green: 1.0, blue: 0.4, alpha: 0.9) : UIColor.cyan
        lineMat.emission.contents = isScanning ? UIColor(red: 0.0, green: 0.6, blue: 0.2, alpha: 0.8) : UIColor(red: 0.0, green: 0.4, blue: 0.6, alpha: 0.5)
        
        // Yarı Saydam İç Alan
        let surfaceMat = SCNMaterial()
        surfaceMat.fillMode = .fill
        surfaceMat.diffuse.contents = isScanning ? UIColor(red: 0.0, green: 0.8, blue: 0.3, alpha: 0.05) : UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.04)
        surfaceMat.isDoubleSided = true
        
        boxGeo.materials = [lineMat, surfaceMat]
        boxWireframeNode.geometry = boxGeo
        
        // 2. Taban Halkası (Masanın üzerine basan alt düzlem)
        let basePlane = SCNPlane(width: CGFloat(size.x), height: CGFloat(size.z))
        let baseMat = SCNMaterial()
        baseMat.fillMode = .lines
        baseMat.diffuse.contents = UIColor.green
        basePlane.materials = [baseMat]
        
        baseRingNode.geometry = basePlane
        baseRingNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        baseRingNode.position = SCNVector3(0, -size.y / 2.0 + 0.001, 0)
    }
}
