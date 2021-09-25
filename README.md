# FNA3D-cs

Automatically updated C# bindings for https://github.com/FNA-XNA/FNA3D with native dynamic link libraries.

## How to use

### From source

1. Download and install [.NET 6](https://dotnet.microsoft.com/download).
2. Fork the repository using GitHub or clone the repository manually with submodules: `git clone --recurse-submodules git@github.com:lithiumtoast/FNA3D-cs.git`.
3. Build the native library by running `./library.sh` on macOS or Linux and `.\library.sh` on Windows.
4. Add the C# project `./src/cs/production/FNA3D-cs/FNA3D-cs.csproj` to your solution:
```xml
<ItemGroup>
    <ProjectReference Include="path/to/FNA3D-cs/src/cs/production/FNA3D-cs/FNA3D-cs.csproj" />
</ItemGroup>
```
5. Use https://github.com/lithiumtoast/sdl-cs since FNA3D has native runtime dependency on SDL2 (there is no C# code dependency, it's a C dependency). 

#### Bindgen

If you wish to re-generate the bindings, simple run `./bindgen.sh` on macOS or Linux and `.\bindgen.cmd` on Windows.

## Developers: Documentation

For more information on how C# bindings work, see [`C2CS`](https://github.com/lithiumtoast/c2cs), the tool that generates the bindings for `SDL` and other C libraries.

FNA3D has limited support.

## License

`FNA3D-cs` is licensed under the MIT license (`MIT`) - see the [LICENSE file](LICENSE) for details.

`FNA3D` itself is licensed under the ZLib license (`zlib`) - see https://github.com/FNA-XNA/FNA3D/blob/master/LICENSE for more details.
