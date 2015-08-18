$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$originalContent1 = @'
<Project>
  <ItemGroup>
    <Reference Include="System.Reactive.Core" />
    <Reference Include="System" />
    <Reference Include="System.Core" />
  </ItemGroup>
  <ItemGroup>
    <Compile Include="aaa.cs" />
    <Compile Include="zzz.cs" />
    <Compile Include="hello\world.cs" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="ccc.csproj">
      <Project>{170967A8-EA91-4E41-B4B3-EFC0831A8FB6}</Project>
      <Name>CCC</Name>
    </ProjectReference>
    <ProjectReference Include="aaa.csproj">
      <Project>{170967A8-EA91-4E41-B4B3-EFC0831A8FB6}</Project>
      <Name>AAA</Name>
    </ProjectReference>
  </ItemGroup>
</Project>
'@

$referenceContent1 = @'
<Project>
  <ItemGroup>
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="System.Reactive.Core" />
  </ItemGroup>
  <ItemGroup>
    <Compile Include="aaa.cs" />
    <Compile Include="hello\world.cs" />
    <Compile Include="zzz.cs" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="aaa.csproj">
      <Project>{170967A8-EA91-4E41-B4B3-EFC0831A8FB6}</Project>
      <Name>AAA</Name>
    </ProjectReference>
    <ProjectReference Include="ccc.csproj">
      <Project>{170967A8-EA91-4E41-B4B3-EFC0831A8FB6}</Project>
      <Name>CCC</Name>
    </ProjectReference>
  </ItemGroup>
</Project>
'@

Describe "AutoFix-CsProj" {
    Context "the csproj contains item groups with single element types of Reference Compile and ProjectReference" {
        $testPath = "TestDrive:\test.csproj"
        Set-Content $testPath -value $originalContent1
        $modifiedFiles = AutoFix-CsProj $testPath
        $modifiedContent = Get-Content $testPath -Raw | %{$_ -replace "`r",""} 

        It "should sort all child elements" {
            $modifiedContent | Should Be $referenceContent1
        }
    }
}

$originalContent2 = @'
<Project>
  <ItemGroup>
    <Reference Include="Antlr3.Runtime, Version=3.4.1.9004, Culture=neutral, PublicKeyToken=eb42632606e9261f, processorArchitecture=MSIL">
      <SpecificVersion>False</SpecificVersion>
      <HintPath>$(SolutionDir)packages\Antlr.3.4.1.9004\lib\Antlr3.Runtime.dll</HintPath>
    </Reference>
    <Content Include="Content\bootstrap.css" />
    <Page Include="Views\main.xaml" />
  </ItemGroup>
</Project>
'@

$referenceContent2 = @'
<Project>
  <ItemGroup>
    <Content Include="Content\bootstrap.css" />
    <Page Include="Views\main.xaml" />
    <Reference Include="Antlr3.Runtime, Version=3.4.1.9004, Culture=neutral, PublicKeyToken=eb42632606e9261f, processorArchitecture=MSIL">
      <SpecificVersion>False</SpecificVersion>
      <HintPath>$(SolutionDir)packages\Antlr.3.4.1.9004\lib\Antlr3.Runtime.dll</HintPath>
    </Reference>
  </ItemGroup>
</Project>
'@

Describe "AutoFix-CsProj" {
    Context "the csproj contains item groups with mixed child elements" {
        $testPath = "TestDrive:\test.csproj"
        Set-Content $testPath -value $originalContent2
        $modifiedFiles = AutoFix-CsProj $testPath
        $modifiedContent = Get-Content $testPath -Raw | %{$_ -replace "`r",""} 

        It "should sort and keep all child elements" {
            $modifiedContent | Should Be $referenceContent2
        }
    }
}