import Metal
import MetalKit

protocol MTVideoViewDelegate: AnyObject {
    func videoView(_ videoView: MTVideoView, didChangeVideoSize size: CGSize)
    func videoView(_ videoView: MTVideoView, didChangeVisibility hasVideo: Bool)
}

class MTVideoView: NSObject {
    
    weak var delegate: MTVideoViewDelegate?

    public var hasVideo: Bool = false {
        didSet {
            delegate?.videoView(self, didChangeVisibility: hasVideo)
        }
    }
    
    private let m_device: MTLDevice
    private let m_layer: MTKView
    
    private let m_vertexData: [Float] = [
      -1.0,  1.0, 0.0,
       1.0,  1.0, 0.0,
      -1.0, -1.0, 0.0,
       1.0, -1.0, 0.0
    ]
    private var m_vertexBuffer: MTLBuffer!
    
    var m_pipelineState: MTLRenderPipelineState!
    var m_commandQueue: MTLCommandQueue!
    var m_viewSize: CGSize = CGSize()

    var m_videoSize: CGSize = .zero {
        didSet {
            let width = m_viewSize.width
            let height = m_videoSize.height * width / m_videoSize.width
            let drawableSize = CGSize(width: width, height: height)

            m_layer.drawableSize = drawableSize
        }
    }

    var m_img: CVImageBuffer?
    
    var m_textureCache: CVMetalTextureCache?
    var m_yTexture: MTLTexture?
    var m_uvTexture: MTLTexture?

//    var m_timer: CADisplayLink!

    init(_ view: MTKView) {
        m_device = MTLCreateSystemDefaultDevice()!
        m_layer = view

        m_layer.isHidden = false
        m_layer.device = m_device
        m_layer.enableSetNeedsDisplay = true

        let dataSize = m_vertexData.count * MemoryLayout.size(ofValue: m_vertexData[0])
        m_vertexBuffer = m_device.makeBuffer(bytes: m_vertexData, length: dataSize, options: [])
        
        let defaultLibrary = m_device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "i420_fragment")
        let vertexProgram = defaultLibrary.makeFunction(name: "i420_vertex")
            
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        m_pipelineState = try! m_device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        m_commandQueue = m_device.makeCommandQueue()
        
//        m_timer = CADisplayLink(target: self, selector: #selector(onDisplayTimer))
//        m_timer.add(to: RunLoop.main, forMode: .default)
        
        super.init()
        m_layer.delegate = self

        var res = kCVReturnSuccess
        res = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, m_device, nil, &m_textureCache)
        if(res != kCVReturnSuccess) {
            BHLog.w("Fail create texture cache \(res)")
        }

        m_viewSize = m_layer.drawableSize
        BHLog.p("Video view inited with size \(self.m_viewSize.width) x \(self.m_viewSize.height)")
    }
    
    deinit {
        delegate = nil
    }

    // MARK: - Public

    func pushImage(_ img: CVImageBuffer) {
        m_img = img
        m_layer.setNeedsDisplay()
    }

    // MARK: - Private

    private func doDraw() {
        guard let drawable = m_layer.currentDrawable else { return }
//        m_log.debug("draw frame ")

        var yCVTex: CVMetalTexture? = nil
        var uvCVTex: CVMetalTexture? = nil

        if let img = m_img {
            let size   = CVImageBufferGetDisplaySize(img)
            var width  = Int(size.width)
            var height = Int(size.height)
            
            if m_videoSize != size {
                m_videoSize = size
            }

            var res = kCVReturnSuccess

            res = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, m_textureCache!, img, nil, .r8Unorm, width, height, 0, &yCVTex)
            if(res != kCVReturnSuccess) {
                let pf = String(format: "%08X", CVPixelBufferGetPixelFormatType(img))
                BHLog.w("Fail load pixels to Y texture \(res), pf: \(pf)")
            } else {
                m_yTexture = CVMetalTextureGetTexture(yCVTex!)
            }

            width  = (width  >> 1)
            height = (height >> 1)

            res = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, m_textureCache!, img, nil, .rg8Unorm, width, height, 1, &uvCVTex)
            if(res != kCVReturnSuccess) {
                let pf = String(format: "%08X", CVPixelBufferGetPixelFormatType(img))
                BHLog.w("Fail load pixels to UV texture \(res), pf: \(pf)")
            } else {
                m_uvTexture = CVMetalTextureGetTexture(uvCVTex!)
            }

            CVMetalTextureCacheFlush(m_textureCache!, 0)

            m_img = nil
        }

        guard
            let yMTLTex : MTLTexture = m_yTexture,
            let uvMTLTex : MTLTexture = m_uvTexture
        else {
            return
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture    = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 55.0/255.0, alpha: 1.0)

        let commandBuffer = m_commandQueue.makeCommandBuffer()!
        let renderEncoder: MTLRenderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

        renderEncoder.setRenderPipelineState(m_pipelineState)
        renderEncoder.setVertexBuffer(m_vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(yMTLTex, index: 0)
        renderEncoder.setFragmentTexture(uvMTLTex, index: 1)

        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        renderEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        yCVTex = nil
        uvCVTex = nil
    }
}

// MARK: - MTKViewDelegate

extension MTVideoView: MTKViewDelegate {

    func mtkView(_ _: MTKView, drawableSizeWillChange size: CGSize) {
        BHLog.p("New video size: \(size.width) x \(size.height)")
        m_viewSize = size
        
        delegate?.videoView(self, didChangeVideoSize: size)
    }

    func draw(in: MTKView) {
        doDraw()
    }
}
