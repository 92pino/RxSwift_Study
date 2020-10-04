//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

//class Observable<T> {
//  private let task: (@escaping (T) -> Void) -> Void
//
//  init(task: @escaping (@escaping (T) -> Void) -> Void) {
//    self.task = task
//  }
//
//  func subscribe(_ f: @escaping (T) -> Void) {
//    task(f)
//  }
//}

class ViewController: UIViewController {
  @IBOutlet var timerLabel: UILabel!
  @IBOutlet var editView: UITextView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
    }
  }
  
  private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
    guard let v = v else { return }
    UIView.animate(withDuration: 0.3, animations: { [weak v] in
      v?.isHidden = !s
      }, completion: { [weak self] _ in
        self?.view.layoutIfNeeded()
    })
  }
  
  // PromiseKit
  // Bolt
  // RxSwift
  // 비동기로 생긴 결과값을 completion이 아닌 return 값으로 전달
  // return 값을 사용하기 위해선 subscribe를 사용
  
  
  // Observable의 생명주기
  /*
   
   1. Create  ==> Observable이 생성
   2. Subscribe ==> 이 떄 실행.
   3. onNext  ==> 데이터 전달
   // ------ 끝 ------
   // Observable이 종료되면 클로저가 사라지면서 순환참조 해결
   4. onCompleted || onError
   5. Disposed
   
   // 한번 onCompleted되거나 OnError로 끝나면 재사용 불가능 ==> 다시 Subscribe를 해줘야닿ㅁ
   
   */
  
  
  func downloadJson(_ url: String) -> Observable<String?> {
    // 1. 비동기로 생기는 데이터를 Observable로 감싸서 리턴하는 방법
    //    return Observable.create() { emiter in
    //      // onNext : 데이터를 전달
    //      emiter.onNext("Hello")
    //      emiter.onNext("World")
    //      // onCompleted : 데이터 전달 끝
    //      emiter.onCompleted()
    //
    //      // create하고 난 이후 disposables를 리턴해줘야된다.
    //      // 그냥 Disposable()을 리턴하는게 아니라 Disposables.create()로 리턴
    //      return Disposables.create()
    //    }
    
    return Observable.create() { emitter in
      let url = URL(string: url)!
      let task = URLSession.shared.dataTask(with: url) { (data, _, error) in
        guard error == nil else {
          emitter.onError(error!)
          return
        }
        
        if let dat = data, let json = String(data: dat, encoding: .utf8) {
          emitter.onNext(json)
        }
        
        emitter.onCompleted()
      }
      
      task.resume()
      
      return Disposables.create() {
        task.cancel()
      }
      
    }
    
    
    //    return Observable.create() { f in
    //      DispatchQueue.global().async {
    //        let url = URL(string: url)!
    //        let data = try! Data(contentsOf: url)
    //        let json = String(data: data, encoding: .utf8)
    //
    //        DispatchQueue.main.async {
    //          f.onNext(json)
    //          // 끝났다는 것을 알림
    //          // 순환참조 문제 해결
    //          // => subscribe 클로저에서 self를 캡쳐하여 순환참조를 발생시키는데 클로저가 생성되서 + 1 증가되고 클로저가 끝나면 -1 되어 순환참조가 없어진다
    //          // => 클로저가 끝나는 경우는 completed, error
    //          f.onCompleted()
    //        }
    //      }
    //
    //      return Disposables.create()
    //    }
  }
  
  // MARK: SYNC
  
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  
  @IBAction func onLoad() {
    editView.text = ""
    setVisibleWithAnimation(activityIndicator, true)
    
    // 2. Observable로 오는 데이터를 받아서 처리하는 방법
    // return값으로 disposable이 출력되는데 사용하지 않을 경우 _로 명시
    // disposable은 취소 시키는 용도
    _ = downloadJson(MEMBER_LIST_URL)
      .debug()
      .subscribe { event in
        // event 종류
        // .next  ==> 데이터를 전달
        // .error ==> 에러 발생하면서 종료
        // .completed ==> 데이터 전달 완료 후 종료
        switch event {
        // 데이터가 전달될 때
        case let .next(json):
          DispatchQueue.main.async {
            self.editView.text = json
            self.setVisibleWithAnimation(self.activityIndicator, false)
          }
        // 데이터가 다 전달되고 끝났을 때
        case .completed:
          break
        // 에러났을 경우
        case .error:
          break
        }
    }
    
    // dispose : 작업 시켜놓은 것을 끝나지 않아도 취소시키는 용도
    // disposable.dispose()
  }
}
