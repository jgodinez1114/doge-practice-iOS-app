
/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

// this view controller is ready to receive strings as messages from
// input bar.
// Can also display messages via a table view with custom cells configured
// with "message" objects
class ChatRoomViewController: UIViewController
{
  //declare properties
  let tableView = UITableView()
  let messageInputBar = MessageInputView()
  let chatRoom = ChatRoom() // a chatRoom property
  
  var messages: [Message] = []
  
  var username = ""
  
  override func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)
    
    // view controller will be chatRoom's delegate
    chatRoom.delegate = self    
    chatRoom.setupNetorkCommunication()
    chatRoom.joinChat(username: username)
    
  } // end viewWillAppear()
  
  override func viewWillDisappear(_ animated: Bool)
  {
    super.viewWillDisappear(animated)
    chatRoom.stopChatSession()  // close stream and remove from run loop
  } // end viewWillDisappear()
} // end ChatRoomViewController class...

//MARK - Message Input Bar
extension ChatRoomViewController: MessageInputDelegate
{
  func sendWasTapped(message: String)
  {
    chatRoom.send(message: message)
  } // end sendWasTapped()
  
} // end ChatRoomVewController extension

// piece which conforms to ChatRoomDelegate protocol
extension ChatRoomViewController: ChatRoomDelegate
{
  func received(message: Message)
  {
    // take message and add the appropriate cell to the table
    insertNewMessageCell(message)
  }
}
