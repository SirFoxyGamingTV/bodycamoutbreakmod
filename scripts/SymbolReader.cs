using System;
using System.Runtime.InteropServices;
public static class OutbreakSymbols {
 [DllImport("dbghelp.dll", SetLastError=true, CharSet=CharSet.Ansi)] public static extern bool SymInitialize(IntPtr p,string path,bool invade);
 [DllImport("dbghelp.dll", SetLastError=true, CharSet=CharSet.Ansi)] public static extern ulong SymLoadModuleEx(IntPtr p,IntPtr file,string image,string module,ulong address,uint size,IntPtr data,uint flags);
 [DllImport("dbghelp.dll", SetLastError=true)] public static extern bool SymFromAddr(IntPtr p,ulong address,out ulong displacement,IntPtr info);
 [DllImport("dbghelp.dll")] public static extern bool SymCleanup(IntPtr p);
 public static string Resolve(IntPtr p,ulong address){
   var b=Marshal.AllocHGlobal(4096);
   try {for(int i=0;i<4096;i++) Marshal.WriteByte(b,i,0); Marshal.WriteInt32(b,88);Marshal.WriteInt32(b,80,4000);
    ulong d; if(!SymFromAddr(p,address,out d,b)) return "error="+Marshal.GetLastWin32Error();
    return Marshal.PtrToStringAnsi(IntPtr.Add(b,84))+" +0x"+d.ToString("x");
   } finally {Marshal.FreeHGlobal(b);}
 }
}
