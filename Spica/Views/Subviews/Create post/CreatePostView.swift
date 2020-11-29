//
// Spica for iOS (Spica)
// File created by Lea Baumgart on 21.11.20.
//
// Licensed under the MIT License
// Copyright © 2020 Lea Baumgart. All rights reserved.
//
// https://github.com/SpicaApp/Spica-iOS
//

import KingfisherSwiftUI
import KMPlaceholderTextView
import SPAlert
import SwiftKeychainWrapper
import SwiftUI

protocol CreatePostDelegate {
	func didSendPost(post: Post?)
	func dismissView()
}

enum PostType {
	case post
	case reply
}

struct CreatePostView: View {
    @State var type: PostType = .post
    @ObservedObject var controller: CreatePostController
    @State var isDrop: Bool = false

    var body: some View {
        Group {
            someView()
        }
    }

    func someView() -> AnyView {
        if #available(iOS 13.4, *) {
            return AnyView(CreatePostSubView(type: $type, controller: controller)
                .onDrop(of: ["public.image"], delegate: self))
        } else {
            return AnyView(CreatePostSubView(type: $type, controller: controller))
        }
    }
}

enum ImageAlertType {
    case manage, source
}

enum CreatePostAlertType {
    case draft, error
}

enum CreatePostSheetType {
    case draft, image
}

struct CreatePostSubView: View {
    @Binding var type: PostType
    @ObservedObject var controller: CreatePostController
    @State private var showingSheet = false
    @State private var sheetType: CreatePostSheetType = .draft
    @State private var showingImageAlert = false
    @State private var imageAlertType: ImageAlertType = .source
    @State var pickerType: UIImagePickerController.SourceType = .photoLibrary

    @State private var textStyle = UIFont.TextStyle.body
    @State var placeholder = "Hi! What's up?"
    @State var reloadTextView: Bool = false

    var body: some View {
        GeometryReader(content: { geometry in
            ZStack {
                VStack {
                    if controller.showingLinkField {
                        TextField("https://micro.alles.cx", text: $controller.enteredLink).textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                            .padding([.top, .leading, .trailing])
                    }
                    HStack {
                        VStack {
                            KFImage(URL(string: "https://avatar.alles.cc/\(KeychainWrapper.standard.string(forKey: "dev.abmgrt.spica.user.id") ?? "_")")!).resizable().frame(width: 40, height: 40, alignment: .center)
                                .cornerRadius(20).padding(.bottom)
                            CircularProgressBar(controller: controller.progressbarController).frame(width: 35, height: 35, alignment: .center)
                            Spacer()
                        }.padding(2)
                        TextView(text: $controller.enteredText, textStyle: $textStyle, placeholder: $placeholder, draftId: $controller.loadedDraftId).frame(minHeight: 100)

                    }.padding()
                    if controller.selectedImage != nil {
                        Image(uiImage: controller.selectedImage).resizable().aspectRatio(contentMode: .fit).frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height / 3).onTapGesture {
                            if controller.selectedImage != nil {
                                imageAlertType = .manage
                                showingImageAlert = true
                            } else {
                                imageAlertType = .source
                                showingImageAlert = true
                            }
                        }.padding()
                    }
                    Spacer()
                    Group {
                        VStack {
                            Divider()
                            HStack {
                                Button(action: {
                                    if controller.selectedImage != nil {
                                        imageAlertType = .manage
                                        showingImageAlert = true
                                    } else {
                                        imageAlertType = .source
                                        showingImageAlert = true
                                    }
                                }, label: {
                                    Image(systemName: controller.selectedImage != nil ? "photo.fill" : "photo").imageScale(.large)
								})
                                Button(action: {
                                    controller.showingLinkField.toggle()
                                }, label: {
                                    Image(systemName: "link").imageScale(.large).padding(.leading)
								})
                                Spacer()
                                if controller.drafts.count > 0 {
                                    Button(action: {
                                        DispatchQueue.main.async {
                                            sheetType = .draft
                                            showingSheet = true
                                        }
                                    }, label: {
                                        Image(systemName: "square.and.pencil").imageScale(.large)
									})
                                }
                            }.padding()
                        }
                    }
                }.frame(maxHeight: .infinity)

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
            .onAppear(perform: {
                self.controller.loadDrafts()
		})
            .navigationBarTitle(Text("\(type == .reply ? String("Reply") : String("Post"))"), displayMode: .inline)
            .navigationBarItems(leading: HStack {
                Button(action: {
                    if controller.enteredText != "" || controller.enteredLink != "" || controller.selectedImage != nil {
                        controller.loadDrafts()
                        if controller.drafts.first(where: { $0.id == controller.loadedDraftId }) != nil {
                            controller.delegate!.dismissView()
                        } else {
                            controller.alertType = .draft
                            controller.showAlert = true
                        }
                    } else {
                        controller.delegate!.dismissView()
                    }
                }, label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray).imageScale(.large).padding(.trailing)
				})
            }, trailing:
            Button(action: {
                controller.showLoadingIndicator = true
                controller.sendButtonEnabled = false
                controller.errorMessage = ""
                controller.showAlert = false
                MicroAPI.default.sendPost(content: controller.enteredText, image: controller.selectedImage, parent: controller.parentID, url: controller.enteredLink) { result in
                    switch result {
                    case let .failure(err):
                        DispatchQueue.main.async { [self] in
                            controller.showLoadingIndicator = false
                            controller.sendButtonEnabled = true
                            controller.errorMessage = "The following error occurred:\n\(err.error.humanDescription)"
                            controller.alertType = .error
                            controller.showAlert = true
                        }
                    case let .success(post):
                        DispatchQueue.main.async { [self] in
                            controller.showLoadingIndicator = false
                            controller.sendButtonEnabled = true
                            controller.deleteCurrentDraftId()
                            controller.delegate!.didSendPost(post: post)
                            controller.delegate!.dismissView()
                            SPAlert.present(title: "Post sent!", preset: .done)
                        }
                    }
                }
            }, label: {
                Image(systemName: "paperplane.fill").imageScale(.large)
				  }).disabled(!controller.sendButtonEnabled))
            .sheet(isPresented: $showingSheet, content: { () -> AnyView in
                if sheetType == .draft {
                    return AnyView(NavigationView {
                        Group {
                            if controller.drafts.count > 0 {
                                List {
                                    ForEach(controller.drafts) { draft in
                                        Group {
                                            VStack(alignment: .leading) {
                                                if draft.content != "" {
                                                    Text("\(draft.content)").padding([.bottom])
                                                } else {
                                                    Text("No content").italic().padding([.bottom])
                                                }
                                                if draft.image != nil || draft.link != nil {
                                                    HStack {
                                                        if draft.image != nil {
                                                            Image(systemName: "photo").foregroundColor(.secondary)
                                                        }
                                                        if draft.link != nil {
                                                            Image(systemName: "link").foregroundColor(.secondary)
                                                        }
                                                    }
                                                }
                                                Text("Created: \(RelativeDateTimeFormatter().localizedString(for: draft.createdAt, relativeTo: Date()))").foregroundColor(.secondary).font(.footnote)
                                            }.padding()
                                        }.onTapGesture {
                                            reloadTextView = true
                                            controller.enteredText = draft.content
                                            controller.enteredLink = draft.link != nil ? draft.link! : ""
                                            controller.showingLinkField = draft.link != nil
                                            controller.selectedImage = draft.image != nil ? UIImage(data: Data(base64Encoded: draft.image!, options: .ignoreUnknownCharacters)!) : nil
                                            controller.loadedDraftId = draft.id
                                            showingSheet = false
                                        }
                                    }.onDelete { offsets in
                                        controller.drafts.remove(atOffsets: offsets)
                                        UserDefaults.standard.setStructArray(controller.drafts, forKey: "postDrafts")
                                    }
                                }
                            } else {
								VStack {
									Image(systemName: "square.and.pencil").resizable().frame(width: 90, height: 90, alignment: .center).foregroundColor(.gray)
									Text("No drafts").bold().font(.title).padding()
								}
                            }
                        }.navigationBarTitle(Text("Drafts"))
						.navigationBarItems(leading: Button(action: {
							showingSheet = false
						}, label: {
							Image(systemName: "xmark.circle.fill").foregroundColor(.gray).imageScale(.large).padding(.trailing)
						}))
                    }.onAppear(perform: {
                        controller.loadDrafts()
				}))
                } else {
                    return AnyView(ImagePicker(image: $controller.selectedImage, pickerType: pickerType))
                }
		})
            .alert(isPresented: $controller.showAlert, content: {
                if controller.alertType == .draft {
                    return Alert(title: Text("Save draft?"), message: Text("Do you want to save your post as a draft?"), primaryButton: .default(Text("Save"), action: {
                        controller.saveAsDraft()
                        controller.delegate!.dismissView()
				}), secondaryButton: .destructive(Text("Don't save"), action: {
                        controller.delegate!.dismissView()
				}))
                } else {
                    return Alert(title: Text("Error"), message: Text(controller.errorMessage), dismissButton: .cancel())
                }
		})
            .actionSheet(isPresented: $showingImageAlert, content: {
                if imageAlertType == .source {
                    var buttons = [ActionSheet.Button]()
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        buttons.append(.default(Text("Camera"), action: {
                            pickerType = .camera
                            showingImageAlert = false
                            sheetType = .image
                            showingSheet = true
							 }))
                    }
                    buttons.append(.default(Text("Library"), action: {
                        pickerType = .photoLibrary
                        showingImageAlert = false
                        sheetType = .image
                        showingSheet = true
							}))
                    buttons.append(.cancel())
                    return ActionSheet(title: Text("Select a source"), buttons: buttons)
                } else {
                    return ActionSheet(title: Text("Manage image"), message: Text("Please select an option"), buttons: [
                        .default(Text("Select another image"), action: {
                            DispatchQueue.main.async {
                                showingImageAlert = false
                                imageAlertType = .source
                                showingImageAlert = true
                            }
								}),
                        .destructive(Text("Remove image"), action: {
                            controller.selectedImage = nil
                            showingImageAlert = false
								}),
                        .cancel(),
                    ])
                }
		})
    }
}

@available(iOS 13.4, *)
extension CreatePostView: DropDelegate {
    func dropEntered(info _: DropInfo) {
        isDrop = true
    }

    func dropExited(info _: DropInfo) {
        isDrop = false
    }

    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: ["public.image"])
    }

    func performDrop(info: DropInfo) -> Bool {
        guard
            let itemProvider = info.itemProviders(for: ["public.image"]).first
        else { return false }

        itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { item, _ in
            if item != nil {
                let image = UIImage(data: item!)
                DispatchQueue.main.async {
                    controller.selectedImage = image
                }
            }
        }

        return true
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
    @Binding var draftId: String

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

    func updateUIView(_ uiView: KMPlaceholderTextView, context _: Context) {
        if draftId != "" {
            uiView.text = text
        }
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
            text.wrappedValue = textView.text
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
    var pickerType: UIImagePickerController.SourceType = .photoLibrary

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = pickerType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
