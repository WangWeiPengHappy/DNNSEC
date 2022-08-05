//
//  ContentView.swift
//  TestMultiApp
//
//  Created by iCore on 2022/8/1.
//

import SwiftUI

struct ContentView: View {
    @State var myStr:String = "status"
    @State var myColor:Color = .black;
    @State var myResult:String = "result"
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(self.myStr)
                .foregroundColor(myColor)
            
            Button("DNSSEC", action: DNSSEC)
                .padding(10)
            
            Text(self.myResult)
                .padding(10)
        }
        .padding()
    }
    func DNSSEC(){
        self.myStr = "waiting"
        self.myColor = .black
        Task{
            await self.RequestUrl()
        }
    }
    func RequestUrl() async->Bool{
        var ret = false;
            var url_str = "http://www.bindsec.cn/";
            url_str.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
            //let url_url = URL.init(string: url_str)
            let url_url = URL.init(string: url_str)
            var request = URLRequest.init(url: url_url!)
            request.requiresDNSSECValidation = true;
            let NwSession = URLSession.shared
            print("request:", url_url)
            let NwTask = NwSession.dataTask(with: request){
                (data, urlResponse, error) in
                if (data != nil) || (urlResponse != nil)  {
                    print("data: ", data)
                    print("urlResponse: ", urlResponse)
                    ret = true
                    self.myColor = .green
                    self.myStr = "Success"
                    self.myResult = urlResponse?.url?.absoluteString ?? "null"
                }else{
                    print("error: ", error)
                    self.myColor = .red
                    self.myStr = "Fail"
                    self.myResult = "\(error)"
                }
            }
            NwTask.resume()
        return ret;
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

