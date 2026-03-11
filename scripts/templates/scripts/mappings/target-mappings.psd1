@{
    Mappings = @(
        @{
            Name = 'stm32f407vg'
            MatchDeviceIds = @('0X413')
            MatchFamilyRegex = 'STM32F405|STM32F407|STM32F415|STM32F417'
            Device = 'STM32F407VG'
            PackID = 'Keil.STM32F4xx_DFP.3.0.0'
            Cpu = 'IRAM(0x20000000,0x20000) IROM(0x08000000,0x100000) CPUTYPE("Cortex-M4") FPU2 CLOCK(12000000) ELITTLE'
            FlashDriverDll = 'UL2CM3(-S0 -C0 -P0 -FD20000000 -FC1000 -FN1 -FF0STM32F4xx_1024 -FS08000000 -FL100000 -FP0($$Device:STM32F407VG$CMSIS\\Flash\\STM32F4xx_1024.FLM))'
            RegisterFile = '$$Device:STM32F407VG$CMSIS\\Device\\ST\\STM32F4xx\\Include\\stm32f407xx.h'
            SFDFile = '$$Device:STM32F407VG$CMSIS\\SVD\\STM32F407.svd'
            SimDllName = 'SARMCM4.DLL'
            SimDlgDllArguments = '-pCM4'
            TargetDllName = 'SARMCM4.DLL'
            TargetDlgDllArguments = '-pCM4'
            AdsCpuType = '"Cortex-M4"'
        },
        @{
            Name = 'stm32f103c8'
            MatchDeviceIds = @('0X410','0X412')
            MatchFamilyRegex = 'STM32F10'
            Device = 'STM32F103C8'
            PackID = 'Keil.STM32F1xx_DFP.2.4.1'
            Cpu = 'IRAM(0x20000000,0x5000) IROM(0x08000000,0x10000) CPUTYPE("Cortex-M3") CLOCK(12000000) ELITTLE'
            FlashDriverDll = 'UL2CM3(-S0 -C0 -P0 -FD20000000 -FC1000 -FN1 -FF0STM32F10x_128 -FS08000000 -FL020000 -FP0($$Device:STM32F103C8$Flash\\STM32F10x_128.FLM))'
            RegisterFile = '$$Device:STM32F103C8$Device\\Include\\stm32f10x.h'
            SFDFile = '$$Device:STM32F103C8$SVD\\STM32F103xx.svd'
            SimDllName = 'SARMCM3.DLL'
            SimDlgDllArguments = '-pCM3'
            TargetDllName = 'SARMCM3.DLL'
            TargetDlgDllArguments = '-pCM3'
            AdsCpuType = '"Cortex-M3"'
        }
    )
}
