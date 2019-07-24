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

// define a protocol to share message objects
protocol ChatRoomDelegate: class
{
  func received(message: Message)
}

class ChatRoom: NSObject // inherit from root class
{
  // weak optional property to hold a reference to whomever decides to b ChatRoom delegate
  weak var delegate: ChatRoomDelegate?
  
  //1
  var inputStream: InputStream! // a stream for read-only
  var outputStream: OutputStream! // a stream for write-only
  
  //2
  var username = ""
  
  //3
  let maxReadLength = 4096  // puts a cap on data you can send in any single message
  
  func setupNetorkCommunication()
  {
    //1. set up 2 intitial socket streams w/o mem management
    var readStream: Unmanaged<CFReadStream>? // propogate to an unmanaged object reference
    var writeStream: Unmanaged<CFWriteStream>?
    
    //2.
    // create readable and writable streams to TCP/IP host
    // four-argument func
    // 1 - type of allocator
    // 2 - hostname
    // 3 - connection port
    // 4 - pass in the pointers to your read and write streams so
    //     the function can initialize them with internal read and write streams
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, "localhost" as CFString, 80, &readStream, &writeStream)
    
    // get value of unmanaged reference and consume it as unbalanced retain of it
    // this helps avoid a memory leak
    inputStream = readStream!.takeRetainedValue()
    outputStream = writeStream!.takeRetainedValue()
    
    // claim to be inputStream's delegate
    inputStream.delegate = self // set receiver's delegate
    
    // create a run loop to react to networking events properly
    inputStream.schedule(in: .current, forMode: .common)
    outputStream.schedule(in: .current, forMode: .common)
    
    // open the stream
    inputStream.open()
    outputStream.open()
  } // end setupNetworkCommunication()
  
  // allow a user to enter chat room
  func joinChat(username:String)
  {
    // construct message and return data with utf8 encoding
    // and chat room protocol
    let data = "iam:\(username)".data(using: .utf8)!
    
    // save the name to use it to send chat msges later
    self.username = username
    
    // provide a convenient way to work w/ an unsafe pointer version of data within a safe closure
    _ = data.withUnsafeBytes
      {
          guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else
          {
            print("Error joining chat")
            return
          }
      
      // write message to the output stream. write(_,maxLength:) takes a reference
      // to an unsafe pointer to bytes as first arg
      outputStream.write(pointer, maxLength: data.count)
     }
  } // end joinChat()
  
  // allow user to send/ receive actual text when Send button is input
  func send(message: String)
  {
    // prepend msg to sent text
    let data = "msg:\(message)".data(using: .utf8)!
    
    _ = data.withUnsafeBytes
      {
        guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else
        {
          print("Error joining chat")
          return
        }
        outputStream.write(pointer, maxLength: data.count)
      }
  } // end send()
  
  // end the session
  func stopChatSession()
  {
    inputStream.close()
    outputStream.close()
  } // end stopChatSession()
} // end ChatRoom class

// need to use inputStream to catch messages (showing up as a cell in ChatRoomViewController's table of messages)
// turn them into Message objects
// pass them off to the table

// StreamDelegate is an interface used by delegates of a stream for event handling
extension ChatRoom: StreamDelegate
{
  func stream(_ aStream: Stream, handle eventCode: Stream.Event)
  {
    switch eventCode
    {
    // use instance property of Bool which indicates wheter the receiver has bytes available to read
    case .hasBytesAvailable:  // indicates there is an incoming message to read
      print("new message received")
      readAvailableBytes(stream: aStream as! InputStream)
    case .endEncountered:
      stopChatSession()
      print("new message received")
    // if error occurred on the stream
    case .errorOccurred:
      print("error occurred")
    // use instance property (boolean) which indicates whehter the receiver can written to
    case .hasSpaceAvailable:
      print("has space available")
    default:
      print("other event ...")
    } // end eventCode switch
  } // end stream()
  
  private func readAvailableBytes(stream: InputStream)
  {
    // set up a buffer into which you can read the incoming bytes
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)  // unsigned 8-bit integer
    
    // loop while your input stream still has bytes to read
    while stream.hasBytesAvailable
    {
      // call read(_:maxLength:) each time to read bytes from stream and put them in buffer passed in
      let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
      
      // check that bytes still coming in
      if numberOfBytesRead < 0, let error = stream.streamError
      {
        print(error)
        break
      }
      
      // construct the message object
      if let message = processedMessageString(buffer: buffer, length: numberOfBytesRead)
      {
        // NOtify interestd parties
        delegate?.received(message: message)
      }
    } // end while stream has bytes available
  } // end readAvailableBytes()
  
  // helper function to convert buffer into Message object
  private func processedMessageString(buffer: UnsafeMutablePointer<UInt8>, length: Int)->Message?
  {
    //1. initialize a string using buffer & length passed in
    //   tell String to free up the buffer of all bytes when done
    //   then split the incoming messsage on the ":" char
    //   this will treat the sender's name & message as separate strings
    guard
      let stringArray = String(
        bytesNoCopy: buffer, length: length, encoding: .utf8, freeWhenDone: true
        )?.components(separatedBy: ":"),
    let name = stringArray.first,
    let message = stringArray.last
      else {
      return nil
    }
    //2.
    let messageSender: MessageSender = (name == self.username) ? .ourself : .someoneElse
    
    return Message(message: message, messageSender: messageSender, username: name)
  } // end processedMessageString()
} // end ChatRoom extension
