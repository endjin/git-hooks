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
        $modifiedContent = Get-Content $testPath -Raw

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
        $modifiedContent = Get-Content $testPath -Raw

        It "should sort and keep all child elements" {
            $modifiedContent | Should Be $referenceContent2
        }
    }
}

$originalContent3 = @'
<Project>
  <ItemGroup>
    <Compile Include="aaa.cs" />
    <Compile Include="aaa.cs" />
  </ItemGroup>
</Project>
'@

$referenceContent3 = @'
<Project>
  <ItemGroup>
    <Compile Include="aaa.cs" />
  </ItemGroup>
</Project>
'@

Describe "AutoFix-CsProj" {
    Context "the csproj contains item groups with duplicate children" {
        $testPath = "TestDrive:\test.csproj"
        Set-Content $testPath -value $originalContent3
        $modifiedFiles = AutoFix-CsProj $testPath
        $modifiedContent = Get-Content $testPath -Raw

        It "should remove the duplicate item group children" {
            $modifiedContent | Should Be $referenceContent3
        }
    }
}

$originalContent4 = @'
<configuration>
  <runtime>
    <assemblyBinding>
      <dependentAssembly>
        <assemblyIdentity name="log4net" publicKeyToken="null" culture="neutral" />
        <codeBase version="1.2.11.0" href="bin\log4net-nokey\log4net.dll" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="log4net" publicKeyToken="669e0ddf0bb1aa2a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-1.2.13.0" newVersion="1.2.13.0" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
'@

$referenceContent4 = @'
<configuration>
  <runtime>
    <assemblyBinding>
      <dependentAssembly>
        <assemblyIdentity name="log4net" publicKeyToken="669e0ddf0bb1aa2a" culture="neutral" />
        <bindingRedirect oldVersion="0.0.0.0-1.2.13.0" newVersion="1.2.13.0" />
      </dependentAssembly>
      <dependentAssembly>
        <assemblyIdentity name="log4net" publicKeyToken="null" culture="neutral" />
        <codeBase version="1.2.11.0" href="bin\log4net-nokey\log4net.dll" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
'@

Describe "AutoFix-WebConfig" {
    Context "the web.config contains multiple bindingRedirects with equal name" {
        $testPath = "TestDrive:\web.config"
        Set-Content $testPath -value $originalContent4
        $modifiedFiles = AutoFix-WebConfig $testPath
        $modifiedContent = Get-Content $testPath -Raw

        It "should sort the duplicate bindingRedirect by name and publicKeyToken" {
            $modifiedContent | Should Be $referenceContent4
        }
    }
}

$originalContent5 = @'
<?xml version="1.0" encoding="utf-8"?>
<root>
  <data name="ccc" xml:space="preserve">
    <value>ccc</value>
  </data>
  <data name="aaa" xml:space="preserve">
    <value>aaa</value>
  </data>
</root>
'@

$referenceContent5 = @'
<?xml version="1.0" encoding="utf-8"?>
<root>
  <data name="aaa" xml:space="preserve">
    <value>aaa</value>
  </data>
  <data name="ccc" xml:space="preserve">
    <value>ccc</value>
  </data>
</root>
'@

Describe "AutoFix-Resx" {
    Context "the resx contains multiple data with different name" {
        $testPath = "TestDrive:\Strings.resx"
        Set-Content $testPath -value $originalContent5
        $modifiedFiles = AutoFix-Resx $testPath
        $modifiedContent = Get-Content $testPath -Raw

        It "should sort the data by name" {
            $modifiedContent | Should Be $referenceContent5
        }
    }
}

$originalContent6 = @'
<Project>
<ItemGroup>
<None Update="a_unique_file">
  <CopyToOutputDirectory>Always</CopyToOutputDirectory>
</None>
<None Update="another_unique_file">
  <CopyToOutputDirectory>Always</CopyToOutputDirectory>
</None>
</ItemGroup>
</Project>
'@

$referenceContent6 = @'
<Project>
<ItemGroup>
<None Update="a_unique_file">
  <CopyToOutputDirectory>Always</CopyToOutputDirectory>
</None>
<None Update="another_unique_file">
  <CopyToOutputDirectory>Always</CopyToOutputDirectory>
</None>
</ItemGroup>
</Project>
'@

Describe "AutoFix-CsProj" {
    Context "the csproj contains item groups with duplicate children" {
        $testPath = "TestDrive:\test.csproj"
        Set-Content $testPath -value $originalContent6
        $modifiedFiles = AutoFix-CsProj $testPath
        $modifiedContent = Get-Content $testPath -Raw

        It "should remain as it is" {
            $modifiedContent | Should Be $referenceContent6
        }
    }
}