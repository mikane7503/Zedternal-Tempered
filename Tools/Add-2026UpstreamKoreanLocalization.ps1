[CmdletBinding()]
param(
    [string]$LocalizationPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'ZedternalTempered\Localization\KOR\ZedternalTempered.kor')
)

$ErrorActionPreference = 'Stop'
$path = [IO.Path]::GetFullPath($LocalizationPath)
$text = [IO.File]::ReadAllText($path)

$block = @'

; === Unlimited 2026-08 신규 콘텐츠 한국어 ===
[ZTUpgrade_Perk_Fastball]
UpgradeName="패스트볼"
PerkUpgradeDescription1="서로 마주 본 팀원을 조준하고 <font color=\"#ffc832\">M</font>을 눌러 조준 방향으로 발사합니다. 재사용 대기시간은 <font color=\"#be4d25\">10초</font>입니다."
PerkUpgradeDescription2="발사된 팀원은 낙하 피해를 받지 않으며, 착지할 때 자신을 회복시키는 폭발 충격파를 일으킵니다."
PerkUpgradeDescription3="레벨당 충격파 피해가 <font color=\"#77d914\">+%x%%</font> 증가하며 착지 속도에 따라 추가 증가합니다."
PerkUpgradeDescription4="<font color=\"#8B0000\">레벨 10:</font> 충격파 범위가 <font color=\"#77d914\">50%</font> 증가합니다."
PerkUpgradeDescription5="<font color=\"#8B0000\">레벨 20:</font> 발사력이 <font color=\"#77d914\">60%</font> 증가하고 착지 회복량이 크게 증가합니다."

[ZTUpgrade_Perk_Goalkeeper]
UpgradeName="골키퍼"
PerkUpgradeDescription1="<font color=\"#ffc832\">N</font>을 눌러 <font color=\"#77d914\">0.6초</font> 동안 전방의 적 투사체를 잡습니다. 실패하면 <font color=\"#be4d25\">6초</font>의 재사용 대기시간이 적용됩니다."
PerkUpgradeDescription2="투사체를 보유한 상태에서 다시 누르면 폭발 화염구로 되던집니다."
PerkUpgradeDescription3="레벨당 반사 투사체 피해가 <font color=\"#77d914\">+%x%%</font> 증가합니다."
PerkUpgradeDescription4="<font color=\"#8B0000\">레벨 10:</font> 투사체를 잡을 때마다 방어구를 <font color=\"#77d914\">10</font> 회복합니다."
PerkUpgradeDescription5="<font color=\"#8B0000\">레벨 20:</font> 근거리에서 완벽하게 잡으면 화염구 <font color=\"#ff3399\">3발</font>을 연속 발사합니다."

[ZTUpgrade_Perk_Wishmaster]
UpgradeName="소원술사"
PerkUpgradeDescription1="매 거래 시간마다 도쉬, 체력, 방어구, 탄약, 축복 등을 제공하는 <font color=\"#ffc832\">3개의 소원</font>이 제시됩니다."
PerkUpgradeDescription2="<font color=\"#ffc832\">쉼표</font>로 소원과 대상 플레이어를 순서대로 고르고 <font color=\"#ffc832\">마침표</font>로 확정합니다. 대상에는 자신도 포함될 수 있습니다."
PerkUpgradeDescription3="소원의 <font color=\"#be4d25\">25%</font>는 타락하여 정확히 반대 효과를 줍니다."
PerkUpgradeDescription4="<font color=\"#8B0000\">레벨 10:</font> 타락 확률이 <font color=\"#77d914\">15%</font>로 감소합니다."
PerkUpgradeDescription5="<font color=\"#8B0000\">레벨 20:</font> 선택 가능한 소원이 <font color=\"#FFD700\">4개</font>로 증가합니다."

[ZTUpgrade_Perk_MissingNO]
UpgradeName="미싱노"
PerkUpgradeDescription1="<font color=\"#FF00FF\">메모리 누수:</font> 모든 무기의 예비 탄약이 레벨당 <font color=\"#00FF00\">+%x%%</font> 증가합니다."
PerkUpgradeDescription2="<font color=\"#FF00FF\">에코 탄창:</font> 모든 무기의 탄창 크기가 레벨당 <font color=\"#00FF00\">+%x%%</font> 증가합니다."
PerkUpgradeDescription3="공격할 때 약 <font color=\"#00FF00\">%x%%</font> 확률로 추가 피해, 도쉬, 탄약 환급, 체력 재생 중 하나가 무작위로 발동합니다."
PerkUpgradeDescription4="<font color=\"#8B0000\">레벨 10 - 타입 불일치:</font> 웨이브마다 무기에 무작위 원소 피해 유형이 부여됩니다."
PerkUpgradeDescription5="<font color=\"#8B0000\">레벨 20 - 데이터 유실:</font> 치명상을 25% 확률로 무효화하며, 웨이브 종료 시 10% 확률로 주 무기를 복제합니다. 각각 웨이브당 1회입니다."

[ZTUpgrade_Skill_EagleEye]
UpgradeName="독수리의 눈"
StandardSkillUpgradeDescription="능동 스킬: 10초 동안 헤드샷 피해가 <font color=\"#00ffff\">25%</font> 증가합니다. 재사용 대기시간 60초."
DeluxeSkillUpgradeDescription="능동 스킬: 10초 동안 헤드샷 피해가 <font color=\"#00ffff\">40%</font> 증가합니다. 재사용 대기시간 60초."

[ZTUpgrade_Skill_FastHands]
UpgradeName="빠른 손"
StandardSkillUpgradeDescription="능동 스킬: 10초 동안 발사 속도가 <font color=\"#00ffff\">40%</font> 증가합니다. 재사용 대기시간 60초."
DeluxeSkillUpgradeDescription="능동 스킬: 10초 동안 발사 속도가 <font color=\"#00ffff\">60%</font> 증가합니다. 재사용 대기시간 60초."

[ZTUpgrade_Skill_Bullpen]
UpgradeName="불펜"
StandardSkillUpgradeDescription="패스트볼 착지 충격파로 제드를 처치하면 발사 재사용 대기시간이 즉시 초기화됩니다."
DeluxeSkillUpgradeDescription="패스트볼로 착지할 때마다 발사 재사용 대기시간이 즉시 초기화됩니다."

[ZTUpgrade_Skill_DesignatedHitter]
UpgradeName="지명 타자"
StandardSkillUpgradeDescription="패스트볼로 발사된 뒤 착지하면 8초 동안 피해가 <font color=\"#ff3399\">20%</font> 증가합니다."
DeluxeSkillUpgradeDescription="패스트볼로 발사된 뒤 착지하면 8초 동안 피해가 <font color=\"#ff3399\">40%</font> 증가합니다."

[ZTUpgrade_Skill_FastballSpecial]
UpgradeName="패스트볼 스페셜"
StandardSkillUpgradeDescription="패스트볼 착지 회복량이 2배가 되고 대상이 방어구 <font color=\"#77d914\">15</font>를 얻습니다."
DeluxeSkillUpgradeDescription="패스트볼 착지 회복량이 2배가 되고 대상이 방어구 <font color=\"#77d914\">30</font>을 얻습니다."

[ZTUpgrade_Skill_FollowThrough]
UpgradeName="팔로스루"
StandardSkillUpgradeDescription="넘어지거나 공중에 뜨거나 무력화된 제드에게 주는 피해가 <font color=\"#ff3399\">15%</font> 증가합니다."
DeluxeSkillUpgradeDescription="넘어지거나 공중에 뜨거나 무력화된 제드에게 주는 피해가 <font color=\"#ff3399\">30%</font> 증가합니다."

[ZTUpgrade_Skill_GroundRuleDouble]
UpgradeName="인정 2루타"
StandardSkillUpgradeDescription="패스트볼 착지 충격파 범위가 <font color=\"#77d914\">25%</font> 증가합니다."
DeluxeSkillUpgradeDescription="패스트볼 착지 충격파 범위가 <font color=\"#77d914\">50%</font> 증가합니다."

[ZTUpgrade_Skill_Heater]
UpgradeName="강속구"
StandardSkillUpgradeDescription="패스트볼 발사력 +25%, 착지 충격파 피해 +15%."
DeluxeSkillUpgradeDescription="패스트볼 발사력 +50%, 착지 충격파 피해 +30%."

[ZTUpgrade_Skill_ReliefPitcher]
UpgradeName="구원 투수"
StandardSkillUpgradeDescription="패스트볼 대상이 착지하면 6초 동안 재장전 +20%, 이동 속도 +10%."
DeluxeSkillUpgradeDescription="패스트볼 대상이 착지하면 6초 동안 재장전 +35%, 이동 속도 +20%."

[ZTUpgrade_Skill_SecondWindUp]
UpgradeName="두 번째 와인드업"
StandardSkillUpgradeDescription="무기 교체 속도와 재장전 속도가 각각 <font color=\"#77d914\">10%</font> 증가합니다."
DeluxeSkillUpgradeDescription="무기 교체 속도와 재장전 속도가 각각 <font color=\"#77d914\">18%</font> 증가합니다."

[ZTUpgrade_Skill_Sinker]
UpgradeName="싱커"
StandardSkillUpgradeDescription="패스트볼 착지 충격파에 맞은 모든 제드가 느려집니다."
DeluxeSkillUpgradeDescription="패스트볼 착지 충격파에 맞은 모든 제드가 크게 느려집니다."

[ZTUpgrade_Skill_WindmillWindup]
UpgradeName="윈드밀 와인드업"
StandardSkillUpgradeDescription="패스트볼 재사용 대기시간이 <font color=\"#77d914\">30%</font> 감소합니다."
DeluxeSkillUpgradeDescription="패스트볼 재사용 대기시간이 <font color=\"#77d914\">50%</font> 감소합니다."

[ZTUpgrade_Skill_CleanSheet]
UpgradeName="클린 시트"
StandardSkillUpgradeDescription="8초 동안 피해를 받지 않으면 다음 피격까지 피해가 10% 증가합니다."
DeluxeSkillUpgradeDescription="8초 동안 피해를 받지 않으면 다음 피격까지 피해가 20% 증가합니다."

[ZTUpgrade_Skill_CrowdFavorite]
UpgradeName="관중의 총애"
StandardSkillUpgradeDescription="골키퍼로 투사체를 잡을 때마다 주변 팀원의 체력을 5 회복합니다."
DeluxeSkillUpgradeDescription="골키퍼로 투사체를 잡을 때마다 주변 팀원의 체력을 10, 방어구를 10 회복합니다."

[ZTUpgrade_Skill_InterceptionBonus]
UpgradeName="가로채기 보너스"
StandardSkillUpgradeDescription="골키퍼로 투사체를 잡을 때마다 도쉬 15를 얻습니다."
DeluxeSkillUpgradeDescription="골키퍼로 투사체를 잡을 때마다 도쉬 35를 얻습니다."

[ZTUpgrade_Skill_IronPalms]
UpgradeName="강철 손바닥"
StandardSkillUpgradeDescription="제드의 투사체 및 원거리 공격 피해를 20% 덜 받습니다."
DeluxeSkillUpgradeDescription="제드의 투사체 및 원거리 공격 피해를 35% 덜 받습니다."

[ZTUpgrade_Skill_Punt]
UpgradeName="펀트"
StandardSkillUpgradeDescription="골키퍼의 완벽한 캐치 판정 거리가 75% 증가합니다."
DeluxeSkillUpgradeDescription="골키퍼의 완벽한 캐치 판정 거리가 150% 증가합니다."

[ZTUpgrade_Skill_Rebound]
UpgradeName="리바운드"
StandardSkillUpgradeDescription="골키퍼가 되돌려 보낸 투사체의 피해가 25% 증가합니다."
DeluxeSkillUpgradeDescription="골키퍼가 되돌려 보낸 투사체의 피해가 50% 증가합니다."

[ZTUpgrade_Skill_SafeSlide]
UpgradeName="안전한 슬라이딩"
StandardSkillUpgradeDescription="낙하 피해를 60% 덜 받습니다."
DeluxeSkillUpgradeDescription="낙하 피해를 받지 않습니다."

[ZTUpgrade_Skill_StickyGloves]
UpgradeName="끈끈한 장갑"
StandardSkillUpgradeDescription="골키퍼의 캐치 실패 재사용 대기시간이 33% 빨리 회복됩니다."
DeluxeSkillUpgradeDescription="골키퍼의 캐치 실패 재사용 대기시간이 60% 빨리 회복됩니다."

[ZTUpgrade_Skill_SweeperKeeper]
UpgradeName="스위퍼 키퍼"
StandardSkillUpgradeDescription="골키퍼 캐치 거리 +30%, 전방 캐치 각도가 더 넓어집니다."
DeluxeSkillUpgradeDescription="골키퍼 캐치 거리 +60%, 전방 캐치 각도가 크게 넓어집니다."

[ZTUpgrade_Skill_TrophyCase]
UpgradeName="트로피 진열장"
StandardSkillUpgradeDescription="반사 투사체 처치당 방어구 +1. 웨이브당 최대 25회."
DeluxeSkillUpgradeDescription="반사 투사체 처치당 방어구 +2. 웨이브당 최대 25회."

[ZTUpgrade_Skill_BlessedVessel]
UpgradeName="축복받은 그릇"
StandardSkillUpgradeDescription="최대 방어구가 10 증가합니다."
DeluxeSkillUpgradeDescription="최대 방어구가 20 증가합니다."

[ZTUpgrade_Skill_DjinnsVigor]
UpgradeName="진의 활력"
StandardSkillUpgradeDescription="최대 체력이 10% 증가합니다."
DeluxeSkillUpgradeDescription="최대 체력이 15% 증가합니다."

[ZTUpgrade_Skill_GeniesStep]
UpgradeName="지니의 발걸음"
StandardSkillUpgradeDescription="이동 속도가 5% 증가합니다."
DeluxeSkillUpgradeDescription="이동 속도가 10% 증가합니다."

[ZTUpgrade_Skill_GreaterBoon]
UpgradeName="위대한 은혜"
StandardSkillUpgradeDescription="소원의 양이 50% 증가합니다. 타락한 손실도 함께 증가합니다."
DeluxeSkillUpgradeDescription="소원의 양이 2배가 됩니다. 타락한 손실도 함께 증가합니다."

[ZTUpgrade_Skill_KarmaShield]
UpgradeName="카르마 방패"
StandardSkillUpgradeDescription="한 번에 최대 체력의 25%를 넘는 피해를 받으면 5초 동안 피해를 20% 덜 받습니다."
DeluxeSkillUpgradeDescription="한 번에 최대 체력의 25%를 넘는 피해를 받으면 5초 동안 피해를 35% 덜 받습니다."

[ZTUpgrade_Skill_KarmicBond]
UpgradeName="업의 결속"
StandardSkillUpgradeDescription="팀원에게 준 소원이 절반의 세기로 자신에게도 적용됩니다. 타락한 소원도 포함됩니다."
DeluxeSkillUpgradeDescription="팀원에게 준 소원이 온전한 세기로 자신에게도 적용됩니다. 타락한 소원도 포함됩니다."

[ZTUpgrade_Skill_PactOfGreed]
UpgradeName="탐욕의 계약"
StandardSkillUpgradeDescription="직접 처치할 때마다 추가 도쉬 1을 얻습니다."
DeluxeSkillUpgradeDescription="직접 처치할 때마다 추가 도쉬 2를 얻습니다."

[ZTUpgrade_Skill_SilverTongue]
UpgradeName="달변가"
StandardSkillUpgradeDescription="소원 타락 확률이 5% 감소합니다."
DeluxeSkillUpgradeDescription="소원 타락 확률이 10% 감소합니다."

[ZTUpgrade_Skill_TwinWishes]
UpgradeName="쌍둥이 소원"
StandardSkillUpgradeDescription="거래 시간마다 소원 2개를 부여할 수 있습니다."
DeluxeSkillUpgradeDescription="거래 시간마다 소원 3개를 부여할 수 있습니다."

[ZTUpgrade_Skill_WiderAudience]
UpgradeName="더 많은 청중"
StandardSkillUpgradeDescription="소원 대상 후보가 최대 4명으로 증가합니다."
DeluxeSkillUpgradeDescription="소원 대상 후보가 최대 6명으로 증가합니다."

[ZTUpgrade_Skill_BufferOverflow]
UpgradeName="버퍼 오버플로"
StandardSkillUpgradeDescription="탄창 크기 +30%, 재장전 속도 -15%."
DeluxeSkillUpgradeDescription="탄창 크기 +50%, 재장전 속도 -20%."

[ZTUpgrade_Skill_Checksum]
UpgradeName="체크섬"
StandardSkillUpgradeDescription="웨이브마다 피해, 속도, 재장전, 피해 저항 중 하나가 무작위로 10% 증가합니다."
DeluxeSkillUpgradeDescription="웨이브마다 피해, 속도, 재장전, 피해 저항 중 하나가 무작위로 20% 증가합니다."

[ZTUpgrade_Skill_CorruptedSave]
UpgradeName="손상된 저장 파일"
StandardSkillUpgradeDescription="미싱노의 데이터 유실 생존 확률이 10% 증가합니다."
DeluxeSkillUpgradeDescription="생존 확률이 10% 증가하고 웨이브당 두 번 발동할 수 있습니다."

[ZTUpgrade_Skill_DuplicateEntry]
UpgradeName="중복 항목"
StandardSkillUpgradeDescription="예비 탄약 +20%, 수류탄 +1."
DeluxeSkillUpgradeDescription="예비 탄약 +35%, 수류탄 +2."

[ZTUpgrade_Skill_HexEdit]
UpgradeName="16진수 편집"
StandardSkillUpgradeDescription="미싱노의 글리치에 다섯 번째 결과인 방어구 +5가 추가됩니다."
DeluxeSkillUpgradeDescription="미싱노의 글리치에 다섯 번째 결과인 방어구 +10이 추가됩니다."

[ZTUpgrade_Skill_MemoryLeak]
UpgradeName="메모리 누수"
StandardSkillUpgradeDescription="지속 피해 효과의 피해가 25% 증가합니다."
DeluxeSkillUpgradeDescription="지속 피해 효과의 피해가 50% 증가합니다."

[ZTUpgrade_Skill_NullPointer]
UpgradeName="널 포인터"
StandardSkillUpgradeDescription="공격의 5%가 제드의 공격성을 무효화하여 크게 느려지게 합니다."
DeluxeSkillUpgradeDescription="공격의 10%가 제드의 공격성을 무효화하여 크게 느려지게 합니다."

[ZTUpgrade_Skill_Rollback]
UpgradeName="롤백"
StandardSkillUpgradeDescription="최대 체력의 20%를 넘는 단일 피해를 받으면 4초 동안 그 피해의 30%를 회복합니다."
DeluxeSkillUpgradeDescription="최대 체력의 20%를 넘는 단일 피해를 받으면 4초 동안 그 피해의 50%를 회복합니다."

[ZTUpgrade_Skill_Segfault]
UpgradeName="세그멘테이션 오류"
StandardSkillUpgradeDescription="체력이 15% 미만인 제드에게 주는 피해가 40% 증가합니다."
DeluxeSkillUpgradeDescription="체력이 15% 미만인 제드에게 주는 피해가 80% 증가합니다."

[ZTUpgrade_Skill_StackCorruption]
UpgradeName="스택 손상"
StandardSkillUpgradeDescription="미싱노의 글리치 발동 확률이 5% 증가합니다."
DeluxeSkillUpgradeDescription="미싱노의 글리치 발동 확률이 10% 증가합니다."
'@

foreach ($section in [regex]::Matches($block, '(?m)^\[([^\]]+)\]$')) {
    $name = $section.Groups[1].Value
    if ($text -match "(?m)^\[$([regex]::Escape($name))\]\r?$") {
        throw "Localization section already exists: $name"
    }
}

$eventAdditions = @'
EventName_PassTheBomb="폭탄 돌리기"
EventName_RedLightGreenLight="무궁화꽃이 피었습니다"
EventName_FloorIsLava="바닥은 용암"
EventName_BodyguardBond="경호원 결속"
EventName_BountyBoard="현상금 게시판"
EventName_GoldenZedRelay="황금 제드 릴레이"
EventDesc_PassTheBomb="도화선이 다 타기 전에 팀원과 접촉해 폭탄을 넘기세요"
EventDesc_RedLightGreenLight="빨간불에는 움직이지 마세요. 사격은 가능합니다"
EventDesc_FloorIsLava="이동하는 안전 지대 안에 머무르세요. 밖에 있으면 불탑니다"
EventDesc_BodyguardBond="짝과 가까이 있으면 보호받지만 멀어지면 상대가 피해를 받습니다"
EventDesc_BountyBoard="각자의 현상금 목표를 모두 완료하면 팀 보상을 받습니다"
EventDesc_GoldenZedRelay="황금 제드를 처치한 사람은 전리품을 줍지 못합니다. 팀원이 주워야 합니다"
'@

$eventHeader = '[ZTConfig_EventWave]'
$eventPos = $text.IndexOf($eventHeader)
if ($eventPos -lt 0) { throw 'ZTConfig_EventWave localization section is missing.' }
$eventEnd = $text.IndexOf("`n[", $eventPos + $eventHeader.Length)
if ($eventEnd -lt 0) { $eventEnd = $text.Length }
if ($text.Substring($eventPos, $eventEnd - $eventPos).Contains('EventName_PassTheBomb=')) {
    throw '2026 minigame event localization already exists.'
}
$text = $text.Insert($eventEnd, "`r`n" + $eventAdditions.TrimEnd() + "`r`n")
$text = $text.TrimEnd() + "`r`n" + $block.TrimStart() + "`r`n"

[IO.File]::WriteAllText($path, $text, [Text.Encoding]::Unicode)
Write-Host "Added 2026 upstream Korean localization to $path"
