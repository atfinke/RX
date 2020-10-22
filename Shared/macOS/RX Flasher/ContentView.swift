//
//  ContentView.swift
//  RX Flasher
//
//  Created by Andrew Finke on 9/26/20.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var model = Model()
    
    var body: some View {
        VStack {
            
            TextField("Firmware Path", text: Binding<String>.init(get: {
                return model.formFirmwarePath
            }, set: { v in
                model.formFirmwarePath = v
            }))
            
            Divider()
                .padding(.vertical, 20)
            
            HStack {
                Text((model.isConnected ? "" : "Not ") + "Connected")
                Circle().foregroundColor(model.isConnected ? .green : .red).frame(width: 10, height: 10)
            }
            Text(model.connectedDevicePath)
                .font(.caption)
            
            
            Picker(selection: Binding<String>.init(get: {
                return model.formDeviceType
            }, set: { v in
                model.formDeviceType = v
            }), label: EmptyView()) {
                Text("R1").tag("R1")
                Text("RD").tag("RD")
            }.pickerStyle(SegmentedPickerStyle()).padding(.top)
            
            
            TextField("Device Name", text: Binding<String>.init(get: {
                return model.formDeviceName
            }, set: { v in
                model.formDeviceName = v
            })).padding(.vertical)
            TextField("Device Serial Number", text: Binding<String>.init(get: {
                return model.formDeviceSerialNumber
            }, set: { v in
                model.formDeviceSerialNumber = v
            }))
            Spacer()
            Button("Flash", action: {
                model.flash()
            })
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: .init(get: {
            return model.isDoneFlashing
        }, set: { v in
            model.isDoneFlashing = v
        }), content: {
            Alert(title: Text("Flash Complete"), dismissButton: .default(Text("OK")) {
                model.isDoneFlashing = false
            })
        })
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
