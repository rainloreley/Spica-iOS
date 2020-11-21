//
// Spica for iOS (Spica)
// File created by Adrian Baumgart on 21.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import SwiftUI
import KMPlaceholderTextView
import SPAlert

struct CreatePostView: View {
	
	@State var type: PostType = .post
	@ObservedObject var controller: CreatePostController
	@State private var showingImagePicker = false
	@State private var showingImageAlert = false
	
	@State private var textStyle = UIFont.TextStyle.body
	@State var placeholder = "Hi! What's up?"
	
	@Environment(\.presentationMode) var presentationMode
	
    var body: some View {
		GeometryReader(content: { geometry in
			ZStack {
				VStack {
					if controller.showingLinkField {
						TextField("https://micro.alles.cx", text: $controller.enteredLink).textFieldStyle(RoundedBorderTextFieldStyle())
							.disableAutocorrection(true)
							.autocapitalization(.none)
					}
					HStack {
						VStack {
							Image("leapfp").resizable().frame(width: 40, height: 40, alignment: .center)
								.cornerRadius(20).padding(.bottom)
							CircularProgressBar(controller: controller.progressbarController).frame(width: 35, height: 35, alignment: .center)
							Spacer()
						}.padding(2)
						TextView(text: $controller.enteredText, textStyle: $textStyle, placeholder: $placeholder).frame(minHeight: 100)//.border(Color.green)
						
					}
					if controller.selectedImage != nil {
						Image(uiImage: controller.selectedImage).resizable().aspectRatio(contentMode: .fit).frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height / 3)
					}
				}
				
				if controller.showLoadingIndicator {
					Group {
						VStack {
							ActivityIndicator(isAnimating: .constant(true), style: .large)
							Text("Loading").bold()
						}
					}.frame(width: 180, height: 180, alignment: .center)
					.background(Color(UIColor.secondarySystemBackground).opacity(0.3))
					.cornerRadius(20)
				}
			}
		})
		.padding()
		.navigationBarTitle(Text("\(type == .reply ? String("Reply") : String("Post"))"), displayMode: .inline)
			  .navigationBarItems(leading: HStack {
				  Button(action: {
					  if controller.selectedImage != nil {
						  showingImageAlert = true
					  }
					  else {
						  showingImagePicker = true
					  }
				  }, label: {
					  Image(systemName: controller.selectedImage != nil ? "photo.fill" : "photo").imageScale(.large)
				  })
				  Button(action: {
					controller.showingLinkField.toggle()
				  }, label: {
					  Image(systemName: "link").imageScale(.large).padding(.leading)
				  })
			  }, trailing:
				Button(action: {
					controller.showLoadingIndicator = true
					controller.sendButtonEnabled = false
					controller.errorMessage = ""
					controller.showErrorMessage = false
					MicroAPI.default.sendPost(content: controller.enteredText, image: controller.selectedImage, parent: controller.parentID, url: controller.enteredLink) { (result) in
						switch result {
						case let .failure(err):
							DispatchQueue.main.async { [self] in
								controller.showLoadingIndicator = false
								controller.sendButtonEnabled = true
								controller.errorMessage = "The following error occurred:\n\(err.error.humanDescription)"
								controller.showErrorMessage = true
								//MicroAPI.default.errorHandling(error: err, caller: self.view)
							}
						case let .success(post):
							DispatchQueue.main.async { [self] in
								controller.showLoadingIndicator = false
								controller.sendButtonEnabled = true
								controller.delegate!.didSendPost(post: post)
								controller.delegate!.dismissView()
								SPAlert.present(title: "Post sent!", preset: .done)
							}
						}
					}
				}, label: {
					  Image(systemName: "paperplane.fill").imageScale(.large)
				  }).disabled(!controller.sendButtonEnabled))
			  .sheet(isPresented: $showingImagePicker) {
				  ImagePicker(image: $controller.selectedImage)
			  }
		.alert(isPresented: $controller.showErrorMessage, content: {
			Alert(title: Text("Error"), message: Text(controller.errorMessage), dismissButton: .cancel())
		})
			  .actionSheet(isPresented: $showingImageAlert, content: {
				  ActionSheet(title: Text("Manage image"), message: Text("Please select an option"), buttons: [
								  .default(Text("Select another image"), action: {
									  showingImageAlert = false
									  showingImagePicker = true
								  }),
								  .destructive(Text("Remove image"), action: {
									  controller.selectedImage = nil
									  showingImageAlert = false
								  }),
								  .cancel()
				  ])
		  })

    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
		NavigationView {
			CreatePostView(controller: .init(delegate: nil))
		}
    }
}

struct TextView: UIViewRepresentable {
 
	@Binding var text: String
	@Binding var textStyle: UIFont.TextStyle
	@Binding var placeholder: String
 
	func makeUIView(context: Context) -> KMPlaceholderTextView {
		let textView = KMPlaceholderTextView()
 
		textView.placeholder = placeholder
		textView.placeholderColor = UIColor.tertiaryLabel
		textView.font = UIFont.preferredFont(forTextStyle: textStyle)
		textView.autocapitalizationType = .sentences
		textView.isSelectable = true
		textView.isUserInteractionEnabled = true
		textView.delegate = context.coordinator
 
		return textView
	}
 
	func updateUIView(_ uiView: KMPlaceholderTextView, context: Context) {
		uiView.text = text
		uiView.font = UIFont.preferredFont(forTextStyle: textStyle)
	}
	
 func makeCoordinator() -> Coordinator {
	 Coordinator($text)
 }
  
 class Coordinator: NSObject, UITextViewDelegate {
	 var text: Binding<String>
  
	 init(_ text: Binding<String>) {
		 self.text = text
	 }
  
	 func textViewDidChange(_ textView: UITextView) {
		 self.text.wrappedValue = textView.text
	 }
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
		return newText.count < 500 + 1
	}
 }
}

struct ImagePicker: UIViewControllerRepresentable {
	@Environment(\.presentationMode) var presentationMode
	@Binding var image: UIImage?

	func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.delegate = context.coordinator
		return picker
	}

	func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		
		let parent: ImagePicker
		
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
			if let uiImage = info[.originalImage] as? UIImage {
				parent.image = uiImage
			}

			parent.presentationMode.wrappedValue.dismiss()
		}

		init(_ parent: ImagePicker) {
			self.parent = parent
		}
	}
}
