
//-------------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by the following tool:
//        https://github.com/lithiumtoast/c2cs (v1.4.19.0)
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
// ReSharper disable All
//-------------------------------------------------------------------------------------
using System;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;

using C2CS;

#nullable enable
#pragma warning disable 1591

public static unsafe partial class FNA3D_Image
{
    private const string LibraryName = "FNA3D";

    // Function @ FNA3D_Image.h:73:19 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [DllImport(LibraryName)]
    public static extern byte* FNA3D_Image_Load(FNA3D_Image_ReadFunc readFunc, FNA3D_Image_SkipFunc skipFunc, FNA3D_Image_EOFFunc eofFunc, void* context, int* w, int* h, int* len, int forceW, int forceH, byte zoom);

    // Function @ FNA3D_Image.h:90:15 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [DllImport(LibraryName)]
    public static extern void FNA3D_Image_Free(byte* mem);

    // Function @ FNA3D_Image.h:110:15 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [DllImport(LibraryName)]
    public static extern void FNA3D_Image_SavePNG(FNA3D_Image_WriteFunc writeFunc, void* context, int srcW, int srcH, int dstW, int dstH, byte* data);

    // Function @ FNA3D_Image.h:131:15 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [DllImport(LibraryName)]
    public static extern void FNA3D_Image_SaveJPG(FNA3D_Image_WriteFunc writeFunc, void* context, int srcW, int srcH, int dstW, int dstH, byte* data, int quality);

    // FunctionPointer @ FNA3D_Image.h:46:30 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [StructLayout(LayoutKind.Sequential)]
    public struct FNA3D_Image_ReadFunc
    {
        public delegate* unmanaged<void*, CString8U, int, int> Pointer;
    }

    // FunctionPointer @ FNA3D_Image.h:51:27 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [StructLayout(LayoutKind.Sequential)]
    public struct FNA3D_Image_SkipFunc
    {
        public delegate* unmanaged<void*, int, void> Pointer;
    }

    // FunctionPointer @ FNA3D_Image.h:55:30 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [StructLayout(LayoutKind.Sequential)]
    public struct FNA3D_Image_EOFFunc
    {
        public delegate* unmanaged<void*, int> Pointer;
    }

    // FunctionPointer @ FNA3D_Image.h:94:27 (/home/runner/work/FNA3D-cs/FNA3D-cs/ext/FNA3D/include/FNA3D_Image.h)
    [StructLayout(LayoutKind.Sequential)]
    public struct FNA3D_Image_WriteFunc
    {
        public delegate* unmanaged<void*, void*, int, void> Pointer;
    }
}
