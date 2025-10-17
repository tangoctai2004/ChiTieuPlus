import SwiftUI
import CoreData

// MARK: - Main View
struct CategoryListScreen: View {
    @StateObject private var viewModel: CategoryViewModel
    
    var isPushed: Bool
    
    @State private var selectedType = "expense"
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var showSuccessAlert = false
    @State private var categoryToDelete: Category? = nil
    
    // Bỏ state cho sheet
    // @State private var isShowingAddSheet = false
    
    init(context: NSManagedObjectContext, isPushed: Bool = false) {
        _viewModel = StateObject(wrappedValue: CategoryViewModel(context: context))
        self.isPushed = isPushed
    }
    
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == selectedType }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Custom Header
                CustomHeaderView(
                    selectedType: $selectedType,
                    isEditing: $isEditing,
                    isPushed: self.isPushed
                )
                
                ScrollView {
                    VStack(spacing: 8) {
                        // SỬA ĐỔI: Chuyển Button thành NavigationLink
                        NavigationLink(destination: CategoryAddScreen(viewModel: viewModel)) {
                            HStack(spacing: 12) {
                                Spacer().frame(width: isEditing ? 57 : 24)
                                Text("Thêm danh mục")
                                    .font(.callout)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        
                        // MARK: - Categories List
                        ForEach(filteredCategories) { category in
                            Group {
                                if isEditing {
                                    EditableCategoryRow(
                                        category: category,
                                        isEditing: $isEditing,
                                        onDelete: {
                                            self.categoryToDelete = category
                                            self.showingDeleteConfirmation = true
                                        }
                                    )
                                } else {
                                    // NavigationLink cho việc Edit vẫn giữ nguyên
                                    NavigationLink(destination: CategoryEditScreen(viewModel: viewModel, category: category)) {
                                        EditableCategoryRow(category: category, isEditing: $isEditing)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if isEditing {
                                    Button(role: .destructive) {
                                        self.categoryToDelete = category
                                        self.showingDeleteConfirmation = true
                                    } label: {
                                        Label("Xoá", systemImage: "trash.fill")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .animation(.default, value: isEditing)
            .animation(.default, value: filteredCategories)
            // Bỏ modifier .sheet
            .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
                Button("Chắc chắn xoá", role: .destructive) {
                    deleteConfirmed()
                }
                Button("Không", role: .cancel) { }
            } message: {
                Text("Bạn có chắc chắn muốn xoá danh mục \"\(categoryToDelete?.name ?? "")\" không? Hành động này không thể hoàn tác.")
            }
            .alert("Xoá thành công", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func deleteConfirmed() {
        if let category = categoryToDelete {
            viewModel.deleteCategory(category)
            self.categoryToDelete = nil
            self.showSuccessAlert = true
        }
    }
}

// MARK: - Các View phụ (Không thay đổi)

struct CustomHeaderView: View {
    @Binding var selectedType: String
    @Binding var isEditing: Bool
    
    var isPushed: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            if isPushed {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                }
                .frame(width: 80, alignment: .leading)
            } else {
                Spacer().frame(width: 80)
            }
            
            Spacer()
            Picker("", selection: $selectedType) {
                Text("Chi tiêu").tag("expense")
                Text("Thu nhập").tag("income")
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            Spacer()
            Button(isEditing ? "Hoàn thành" : "Chỉnh sửa") {
                isEditing.toggle()
            }
            .font(.callout)
            .foregroundColor(.primary)
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color.white)
    }
}

struct EditableCategoryRow: View {
    @ObservedObject var category: Category
    @Binding var isEditing: Bool
    var onDelete: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            Image(systemName: category.iconName ?? "questionmark.circle")
                .font(.title3)
                .foregroundColor(IconProvider.color(for: category.iconName))
                .frame(width: 24)
            
            Text(category.name ?? "Không có tên")
                .font(.callout)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditing {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray.opacity(0.7))
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(10)
    }
}

// MARK: - Icon Provider
struct IconProvider {
    struct IconInfo: Identifiable, Hashable {
        let id = UUID()
        let iconName: String
        let color: Color
    }

    static let allIcons: [IconInfo] = [
        IconInfo(iconName: "house.fill", color: .orange),
        IconInfo(iconName: "cart.fill", color: .green),
        IconInfo(iconName: "fork.knife", color: .yellow),
        IconInfo(iconName: "bus.fill", color: .blue),
        IconInfo(iconName: "bolt.fill", color: .yellow),
        IconInfo(iconName: "drop.fill", color: .cyan),
        IconInfo(iconName: "phone.fill", color: .indigo),
        IconInfo(iconName: "wifi", color: .blue),
        IconInfo(iconName: "fuelpump.fill", color: .black),
        IconInfo(iconName: "heart.text.square.fill", color: .red),
        IconInfo(iconName: "tshirt.fill", color: .pink),
        IconInfo(iconName: "pills.fill", color: .mint),
        IconInfo(iconName: "graduationcap.fill", color: .teal),
        IconInfo(iconName: "scissors", color: .gray),
        IconInfo(iconName: "pawprint.fill", color: .brown),
        IconInfo(iconName: "gym.bag.fill", color: .purple),
        IconInfo(iconName: "books.vertical.fill", color: .brown),
        IconInfo(iconName: "wrench.and.screwdriver.fill", color: .gray),
        IconInfo(iconName: "hand.raised.fingers.spread.fill", color: .orange),
        IconInfo(iconName: "person.2.fill", color: .blue),
        IconInfo(iconName: "gift.fill", color: .red),
        IconInfo(iconName: "gamecontroller.fill", color: .purple),
        IconInfo(iconName: "film.fill", color: .indigo),
        IconInfo(iconName: "music.mic", color: .pink),
        IconInfo(iconName: "cup.and.saucer.fill", color: .brown),
        IconInfo(iconName: "airplane", color: .blue),
        IconInfo(iconName: "party.popper.fill", color: .yellow),
        IconInfo(iconName: "wineglass.fill", color: .purple),
        IconInfo(iconName: "ticket.fill", color: .orange),
        IconInfo(iconName: "tree.fill", color: .green),
        IconInfo(iconName: "doc.text.fill", color: .gray),
        IconInfo(iconName: "creditcard.fill", color: .mint),
        IconInfo(iconName: "building.columns.fill", color: .brown),
        IconInfo(iconName: "arrow.up.forward.app.fill", color: .red),
        IconInfo(iconName: "questionmark.circle.fill", color: .gray),
        IconInfo(iconName: "arrow.down.to.line.compact", color: .red),
        IconInfo(iconName: "heart.circle.fill", color: .pink),
        IconInfo(iconName: "briefcase.fill", color: .brown),
        IconInfo(iconName: "shippingbox.fill", color: .orange),
        IconInfo(iconName: "banknote.fill", color: .green),
        IconInfo(iconName: "dollarsign.circle.fill", color: .green),
        IconInfo(iconName: "chart.line.uptrend.xyaxis", color: .cyan),
        IconInfo(iconName: "arrow.up.right.circle.fill", color: .blue),
        IconInfo(iconName: "bag.fill", color: .orange),
        IconInfo(iconName: "person.3.fill", color: .teal),
        IconInfo(iconName: "lightbulb.fill", color: .yellow),
        IconInfo(iconName: "giftcard.fill", color: .red),
        IconInfo(iconName: "arrow.left.arrow.right.circle.fill", color: .purple),
        IconInfo(iconName: "plus.circle.fill", color: .green),
        IconInfo(iconName: "camera.fill", color: .black),
        IconInfo(iconName: "headphones", color: .purple),
        IconInfo(iconName: "desktopcomputer", color: .blue),
        IconInfo(iconName: "bed.double.fill", color: .brown),
        IconInfo(iconName: "leaf.fill", color: .green),
        IconInfo(iconName: "flame.fill", color: .red),
        IconInfo(iconName: "car.fill", color: .purple),
        IconInfo(iconName: "cross.vial.fill", color: .mint),
        IconInfo(iconName: "paintbrush.pointed.fill", color: .orange),
        IconInfo(iconName: "figure.walk", color: .blue),
        IconInfo(iconName: "bicycle", color: .blue),
        IconInfo(iconName: "teddybear.fill", color: .brown),
        IconInfo(iconName: "camera.macro", color: .gray),
        IconInfo(iconName: "eyeglasses", color: .black),
        IconInfo(iconName: "sun.max.fill", color: .yellow),
        IconInfo(iconName: "moon.fill", color: .indigo),
        IconInfo(iconName: "snowflake", color: .cyan),
        IconInfo(iconName: "tornado", color: .gray),
        IconInfo(iconName: "key.fill", color: .orange),
        IconInfo(iconName: "lock.fill", color: .gray),
        IconInfo(iconName: "display", color: .blue),
        IconInfo(iconName: "apple.logo", color: .black),
        IconInfo(iconName: "pc", color: .blue),
        IconInfo(iconName: "printer.fill", color: .gray),
        IconInfo(iconName: "server.rack", color: .black),
        IconInfo(iconName: "simcard.fill", color: .orange),
        IconInfo(iconName: "sdcard.fill", color: .gray),
        IconInfo(iconName: "keyboard.fill", color: .black),
        IconInfo(iconName: "stethoscope.circle.fill", color: .gray),
        IconInfo(iconName: "scope", color: .black),
        IconInfo(iconName: "bandage.fill", color: .orange),
        IconInfo(iconName: "waveform.path.ecg", color: .red),
        IconInfo(iconName: "brain.head.profile", color: .pink),
        IconInfo(iconName: "lungs.fill", color: .red),
        IconInfo(iconName: "mouth.fill", color: .pink),
        IconInfo(iconName: "nose.fill", color: .brown),
        IconInfo(iconName: "mustache.fill", color: .black),
        IconInfo(iconName: "face.smiling.fill", color: .yellow),
        IconInfo(iconName: "comb.fill", color: .gray),
        IconInfo(iconName: "alarm.fill", color: .red),
        IconInfo(iconName: "clock.fill", color: .blue),
        IconInfo(iconName: "hourglass", color: .orange),
        IconInfo(iconName: "calendar", color: .red),
        IconInfo(iconName: "map.fill", color: .green),
        IconInfo(iconName: "globe.americas.fill", color: .blue),
        IconInfo(iconName: "signpost.right.fill", color: .brown),
        IconInfo(iconName: "ruler.fill", color: .yellow),
        IconInfo(iconName: "hammer.fill", color: .brown),
        IconInfo(iconName: "screwdriver.fill", color: .orange),
        IconInfo(iconName: "wrench.fill", color: .gray),
        IconInfo(iconName: "shield.fill", color: .blue),
        IconInfo(iconName: "flag.fill", color: .red),
        IconInfo(iconName: "bell.fill", color: .yellow),
        IconInfo(iconName: "tag.fill", color: .green),
        IconInfo(iconName: "bolt.heart.fill", color: .red),
        IconInfo(iconName: "camera.filters", color: .cyan),
        IconInfo(iconName: "ant.fill", color: .brown),
        IconInfo(iconName: "ladybug.fill", color: .red),
        IconInfo(iconName: "fish.fill", color: .blue),
        IconInfo(iconName: "bird.fill", color: .cyan),
        IconInfo(iconName: "lizard.fill", color: .green),
        IconInfo(iconName: "tortoise.fill", color: .green),
        IconInfo(iconName: "hare.fill", color: .brown),
        IconInfo(iconName: "dog.fill", color: .brown),
        IconInfo(iconName: "cat.fill", color: .orange),
        IconInfo(iconName: "crown.fill", color: .yellow),
        IconInfo(iconName: "cube.fill", color: .orange),
        IconInfo(iconName: "pyramid.fill", color: .yellow),
        IconInfo(iconName: "cone.fill", color: .orange),
        IconInfo(iconName: "cylinder.fill", color: .blue),
        IconInfo(iconName: "octagon.fill", color: .purple),
        IconInfo(iconName: "capsule.fill", color: .red),
        IconInfo(iconName: "diamond.fill", color: .cyan),
        IconInfo(iconName: "lungs.fill", color: .red),
        IconInfo(iconName: "puzzlepiece.extension.fill", color: .blue),
        IconInfo(iconName: "building.2.fill", color: .brown),
        IconInfo(iconName: "storefront.fill", color: .orange),
        IconInfo(iconName: "banknote", color: .green),
        IconInfo(iconName: "chart.pie.fill", color: .blue),
        IconInfo(iconName: "chart.bar.fill", color: .orange),
        IconInfo(iconName: "rosette", color: .yellow),
        IconInfo(iconName: "graduationcap", color: .blue),
        IconInfo(iconName: "studentdesk", color: .brown),
        IconInfo(iconName: "paperclip", color: .gray),
        IconInfo(iconName: "link", color: .blue),
        IconInfo(iconName: "personalhotspot", color: .blue),
        IconInfo(iconName: "network", color: .blue),
        IconInfo(iconName: "icloud.fill", color: .blue),
        IconInfo(iconName: "dot.radiowaves.left.and.right", color: .blue),
        IconInfo(iconName: "antenna.radiowaves.left.and.right", color: .red),
        IconInfo(iconName: "guitars.fill", color: .brown),
        IconInfo(iconName: "pianokeys", color: .black),
        IconInfo(iconName: "paintbrush.fill", color: .orange),
        IconInfo(iconName: "theatermasks.fill", color: .purple),
        IconInfo(iconName: "mic.fill", color: .red)
    ]

    static func color(for iconName: String?) -> Color {
        guard let iconName = iconName else { return .primary }
        return allIcons.first { $0.iconName == iconName }?.color ?? .primary
    }
}
