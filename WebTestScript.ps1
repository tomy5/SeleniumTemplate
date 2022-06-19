
Class UserProfile {
    [String] $Id
    [String] $Password

    setId([String]$Id) {
        $this.Id = $Id
    }
    setPassword([System.Security.SecureString]$Password) {
        # �p�X���[�h���Í�������������ɕϊ�
        $this.Password = $(ConvertFrom-SecureString -SecureString $Password)
    }
}

Function Get-UserProfile {
    $Path = ""

    If (Test-Path $Path) {
        $JsonContent = (Get-Content $Path | ConvertFrom-Json)
    }
    Else {
        $JsonContent = (Out-UserProfile $Path)
    }
    Return $JsonContent
}

Function Out-UserProfile {
    Param(
        [Parameter(Mandatory)]
        [String]$Path
    )

    $JsonContent = New-Object UserProfile

    $Id = Read-Host "���[�UID����͂��Ă��������@"
    $JsonContent.setId($Id)

    $Password = Read-Host "�p�X���[�h����͂��Ă�������" -AsSecureString
    $JsonContent.setPassword($Password)

    ConvertTo-Json -InputObject $JsonContent | Out-File -LiteralPath $Path

    Return $JsonContent
}

Function ConvertTo-PlainText {
    Param(
        [Parameter(Mandatory)]
        [String]$EncryptString
    )

    $Decrypt = ConvertTo-SecureString -String $EncryptString
    # �Í������ꂽ������𕽕��ɕϊ�
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Decrypt)
    $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)

    Return $PlainText
}

Function Logon {
    Param(
        [Parameter(Mandatory)]
        [OpenQA.Selenium.Edge.EdgeDriver]$Driver,
        [UserProfile]$UserProfile
    )

    $Element = Find-SeElement -Driver $Driver -Id "txtLoginId"
    Send-SeKeys -Element $Element -Keys $UserProfile.Id

    $Element = Find-SeElement -Driver $Driver -Id "txtPassword"
    Send-SeKeys -Element $Element -Keys (ConvertTo-PlainText $UserProfile.Password)

    $Element = Find-SeElement -Driver $Driver -Id "ibLogin"
    $Element.Click()
}

Function Start-Edge {
    $UserProfile = Get-UserProfile "profile.json"

    Try {
        Import-Module -Name Selenium -ErrorAction Stop
    }
    Catch {
    "
    Selenium ���W���[���̃C���|�[�g�Ɏ��s���܂����B
    ���̃R�}���h�ŃC���X�g�[�����s���Ă�������: Install-Module -Scope CurrentUser Selenium
    "
        # �I��
        Break
    }

    $Driver = Start-SeEdge -Maximized
    # $Driver.GetType().FullName

    # URL���擾
    $Assets = (Get-Content "assets.json" | ConvertFrom-Json)
    Enter-SeUrl $Assets.Url -Driver $Driver

    Logon -Driver $Driver -UserProfile $UserProfile
    # $Driver.Quit()
}

Start-Edge

# Add-Type -Assembly System.Windows.Forms
# [System.Windows.Forms.MessageBox]::Show("�������������܂���",  "�����ʒm")
Read-Host "�I������ɂ�Enter�������Ă�������"
