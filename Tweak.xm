#include "substrate.h"
#include <string>
#include <cstdio>
#include <chrono>
#include <memory>
#include <vector>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <random>
#include <cstdint>
#include <unordered_map>
#include <map>
#include <functional>
#include <cmath>
#include <chrono>
#include <libkern/OSCacheControl.h>
#include <cstddef>
#include <tuple>
#include <mach/mach.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <dlfcn.h>

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

struct TextureUVCoordinateSet;
struct CompoundTag;
struct Material;
struct BlockSource;
struct PlayerInventoryProxy;

enum class MaterialType : int {
	DEFAULT = 0,
	DIRT,
	WOOD,
	STONE,
	METAL,
	WATER,
	LAVA,
	PLANT,
	DECORATION,
	WOOL = 11,
	BED,
	FIRE,
	SAND,
	DEVICE,
	GLASS,
	EXPLOSIVE,
	ICE,
	PACKED_ICE,
	SNOW,
	CACTUS = 22,
	CLAY,
	PORTAL = 25,
	CAKE,
	WEB,
	CIRCUIT,
	LAMP = 30,
	SLIME
};

enum class BlockSoundType : int {
	NORMAL, GRAVEL, WOOD, GRASS, METAL, STONE, CLOTH, GLASS, SAND, SNOW, LADDER, ANVIL, SLIME, SILENT, DEFAULT, UNDEFINED
};

enum class CreativeItemCategory : unsigned char {
	BLOCKS = 1,
	DECORATIONS,
	TOOLS,
	ITEMS
};

struct Block
{
	void** vtable;
	char filler[0x90-8];
	int category;
	char filler2[0x94+0x19+0x90-4];
};

struct SlabBlock :public Block {};

struct Item {
	void** vtable; // 0
	uint8_t maxStackSize; // 8
	int idk; // 12
	std::string atlas; // 16
	int frameCount; // 40
	bool animated; // 44
	short itemId; // 46
	std::string name; // 48
	std::string idk3; // 72
	bool isMirrored; // 96
	short maxDamage; // 98
	bool isGlint; // 100
	bool renderAsTool; // 101
	bool stackedByData; // 102
	uint8_t properties; // 103
	int maxUseDuration; // 104
	bool explodeable; // 108
	bool shouldDespawn; // 109
	bool idk4; // 110
	uint8_t useAnimation; // 111
	int creativeCategory; // 112
	float idk5; // 116
	float idk6; // 120
	char buffer[12]; // 124
	TextureUVCoordinateSet* icon; // 136
	char filler[100];
};

struct BlockItem :public Item {
	char filler[0xB0];
};

struct ItemInstance {
	uint8_t count;
	uint16_t aux;
	CompoundTag* tag;
	Item* item;
	Block* block;
	int idk[3];
};

struct BlockGraphics {
	void** vtable;
	char filler[0x20 - 8];
	int blockShape;
	char filler2[0x3C0 - 0x20 - 4];
};

/*	1.14's BlockShape
type = enum class BlockShape : int {BlockShape::INVISIBLE = -1, BlockShape::BLOCK, 
    BlockShape::CROSS_TEXTURE, BlockShape::TORCH, BlockShape::FIRE, BlockShape::WATER, 
    BlockShape::RED_DUST, BlockShape::ROWS, BlockShape::DOOR, BlockShape::LADDER, BlockShape::RAIL, 
    BlockShape::STAIRS, BlockShape::FENCE, BlockShape::LEVER, BlockShape::CACTUS, BlockShape::BED, 
    BlockShape::DIODE, BlockShape::IRON_FENCE = 18, BlockShape::STEM, BlockShape::VINE, 
    BlockShape::FENCE_GATE, BlockShape::CHEST, BlockShape::LILYPAD, BlockShape::BREWING_STAND = 25, 
    BlockShape::PORTAL_FRAME, BlockShape::COCOA = 28, BlockShape::TREE = 31, BlockShape::WALL, 
    BlockShape::DOUBLE_PLANT = 40, BlockShape::FLOWER_POT = 42, BlockShape::ANVIL, BlockShape::DRAGON_EGG, 
    BlockShape::STRUCTURE_VOID = 48, BlockShape::BLOCK_HALF = 67, BlockShape::TOP_SNOW, 
    BlockShape::TRIPWIRE, BlockShape::TRIPWIRE_HOOK, BlockShape::CAULDRON, BlockShape::REPEATER, 
    BlockShape::COMPARATOR, BlockShape::HOPPER, BlockShape::SLIME_BLOCK, BlockShape::PISTON, 
    BlockShape::BEACON, BlockShape::CHORUS_PLANT, BlockShape::CHORUS_FLOWER, BlockShape::END_PORTAL, 
    BlockShape::END_ROD, BlockShape::END_GATEWAY, BlockShape::SKULL, BlockShape::FACING_BLOCK, 
    BlockShape::COMMAND_BLOCK, BlockShape::TERRACOTTA, BlockShape::DOUBLE_SIDE_FENCE, 
    BlockShape::ITEM_FRAME, BlockShape::SHULKER_BOX, BlockShape::DOUBLESIDED_CROSS_TEXTURE, 
    BlockShape::DOUBLESIDED_DOUBLE_PLANT, BlockShape::DOUBLESIDED_ROWS, BlockShape::ELEMENT_BLOCK, 
    BlockShape::CHEMISTRY_TABLE, BlockShape::CORAL_FAN = 96, BlockShape::SEAGRASS, BlockShape::KELP, 
    BlockShape::TRAPDOOR, BlockShape::SEA_PICKLE, BlockShape::CONDUIT, BlockShape::TURTLE_EGG, 
    BlockShape::BUBBLE_COLUMN = 105, BlockShape::BARRIER, BlockShape::SIGN, BlockShape::BAMBOO, 
    BlockShape::BAMBOO_SAPLING, BlockShape::SCAFFOLDING, BlockShape::GRINDSTONE, BlockShape::BELL, 
    BlockShape::LANTERN, BlockShape::CAMPFIRE, BlockShape::LECTERN, BlockShape::SWEET_BERRY_BUSH, 
    BlockShape::CARTOGRAPHY_TABLE, BlockShape::COMPOSTER, BlockShape::STONE_CUTTER, 
    BlockShape::HONEY_BLOCK}
*/

enum class LevelSoundEvent : unsigned int {
	ItemUseOn, Hit, Step, Fly, Jump, Break, Place, HeavyStep, 
    Gallop, Fall, Ambient, AmbientBaby, AmbientInWater, Breathe, Death, DeathInWater, 
    DeathToZombie, Hurt, HurtInWater, Mad, Boost, Bow, SquishBig, SquishSmall, FallBig, 
    FallSmall, Splash, Fizz, Flap, Swim, Drink, Eat, Takeoff, Shake, Plop, 
    Land, Saddle, Armor, ArmorPlace, AddChest, Throw, Attack, AttackNoDamage, AttackStrong, 
    Warn, Shear, Milk, Thunder, Explode, Fire, Ignite, Fuse, Stare, Spawn
};

enum class EntityType : int
{
	IDK = 1,
    ITEM = 64,
    PRIMED_TNT,
    FALLING_BLOCK,
    EXPERIENCE_POTION = 68,
    EXPERIENCE_ORB,
    FISHINGHOOK = 77,
    ARROW = 80,
    SNOWBALL,
    THROWNEGG,
    PAINTING,
    LARGE_FIREBALL = 85,
    THROWN_POTION,
    LEASH_FENCE_KNOT = 88,
    BOAT = 90,
    LIGHTNING_BOLT = 93,
    SAMLL_FIREBALL,
    TRIPOD_CAMERA = 318,
    PLAYER,
    IRON_GOLEM = 788,
    SOWN_GOLEM,
    VILLAGER = 1807,
    CREEPER = 2849,
    SLIME = 2853,
    ENDERMAN,
    GHAST = 2857,
    LAVA_SLIME,
    BLAZE,
    WITCH = 2861,
    CHICKEN = 5898,
    COW ,
    PIG,
    SHEEP,
    MUSHROOM_COW = 5904,
    RABBIT = 5906,
    SQUID = 10001,
    WOLF = 22286,
    OCELOT = 22294,
    BAT = 33043,
    PIG_ZOMBIE = 68388,
    ZOMBIE = 199456,
    ZOMBIE_VILLAGER = 199468,
    SPIDER = 264995,
    SILVERFISH = 264999,
    CAVE_SPIDER,
    MINECART_RIDEABLE = 524372,
    MINECART_HOPPER = 524384,
    MINECART_MINECART_TNT,
    MINECART_CHEST,
    SKELETON = 1116962,
    WITHER_SKELETON = 1116974,
    STRAY = 1116976,
    HORSE = 2119447,
    DONKEY,
    MULE,
    SKELETON_HORSE,
    ZOMBIE_HORSE
};

struct LevelData {
	char filler[48];
	std::string levelName;
	char filler2[44];
	int time;
	char filler3[144];
	int gameType;
	int difficulty;
};

struct Level {
	char filler[160];
	LevelData data;
};

struct Entity {
	char filler[64];
	Level* level;
	char filler2[104];
	BlockSource* region;
};

struct Player :public Entity {
	char filler[4400];
	PlayerInventoryProxy* inventory;
};

struct Vec3 {
	float x, y, z;
};

struct BlockPos {
	int x, y, z;
};

struct AABB {
	Vec3 min, max;
	bool valid;
};

struct BlockID {
	static BlockID AIR;

	unsigned char id;

	BlockID() : id(0) {}
	BlockID(unsigned char id) : id(id) {}
	BlockID(const BlockID& other) {id = other.id;}
};

struct FullBlock {
	static FullBlock AIR;

	BlockID id;
	unsigned char aux;

	FullBlock() : id(0), aux(0) {};
	FullBlock(BlockID tileId, unsigned char aux_) : id(tileId), aux(aux_) {}
};

struct ItemGraphics {
	char filler[0x40] {};
};
std::vector<ItemGraphics>* ItemRenderer$mItemGraphics;

namespace Json { class Value; }

Item*** Item$mItems;

typedef void (*MSHookMemory_ptr_t)(void *target, const void *data, size_t size);

#define ENSURE_KERN_SUCCESS(ret) \
if (ret != KERN_SUCCESS) { \
    return false; \
} \


// MARK: - Functions

bool write_memory(void *destination, const void *data, size_t size) { 
    MSHookMemory_ptr_t __MSHookMemory = (MSHookMemory_ptr_t)MSFindSymbol(NULL, "_MSHookMemory");
    if (__MSHookMemory) { 
        // We can use MSHookMemory!
        __MSHookMemory(destination, data, size);
        return true;
    }

    // We can't use MSHookMemory, so try and remap the permissions
    mach_port_t our_port = mach_task_self();

    // Attempt to map as RWX
    ENSURE_KERN_SUCCESS(vm_protect(our_port, (vm_address_t)destination, size, false, VM_PROT_ALL))

    // Write to memory
    ENSURE_KERN_SUCCESS(vm_write(our_port, (vm_address_t)destination, (vm_address_t)data, size))

    // Map back to RX
    ENSURE_KERN_SUCCESS(vm_protect(our_port, (vm_address_t)destination, size, false, VM_PROT_READ | VM_PROT_EXECUTE))

    return true;
}

uint8_t* allPatchData;
size_t allPatchDataStart, allPatchDataLength;

void initPatch() {
	size_t baseAddr = _dyld_get_image_vmaddr_slide(0);
	allPatchDataStart = 0x1000052A0; // __textのアドレス
	allPatchDataLength = 0x100E32F54 - 0x1000052A0; // _textのサイズ

	allPatchData = new uint8_t[allPatchDataLength];
	memcpy(allPatchData, (void*) (baseAddr + allPatchDataStart), allPatchDataLength);
}

void patch(size_t addr, uint8_t *newData, size_t length) {
	memcpy(allPatchData + addr - allPatchDataStart, newData, length);
}

void applyPatches() {
	size_t baseAddr = _dyld_get_image_vmaddr_slide(0);
	if (!write_memory((void*) (baseAddr + allPatchDataStart), allPatchData, allPatchDataLength)) abort();
}

void patchItemPtr() {
	uint8_t patch_data_0[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x1000f3ff8, patch_data_0, 4);
	uint8_t patch_data_1[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x1000f4494, patch_data_1, 4);
	uint8_t patch_data_2[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100351b30, patch_data_2, 4);
	uint8_t patch_data_3[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x1004a4350, patch_data_3, 4);
	uint8_t patch_data_4[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x1004a4518, patch_data_4, 4);
	uint8_t patch_data_5[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007422f8, patch_data_5, 4);
	uint8_t patch_data_6[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100745360, patch_data_6, 4);
	uint8_t patch_data_7[] = {0x18, 0x23, 0x41, 0xf9};
	patch(0x1007467b8, patch_data_7, 4);
	uint8_t patch_data_8[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748124, patch_data_8, 4);
	uint8_t patch_data_9[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007481e8, patch_data_9, 4);
	uint8_t patch_data_10[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007482ac, patch_data_10, 4);
	uint8_t patch_data_11[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748370, patch_data_11, 4);
	uint8_t patch_data_12[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748434, patch_data_12, 4);
	uint8_t patch_data_13[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007484f8, patch_data_13, 4);
	uint8_t patch_data_14[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007485bc, patch_data_14, 4);
	uint8_t patch_data_15[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748680, patch_data_15, 4);
	uint8_t patch_data_16[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748744, patch_data_16, 4);
	uint8_t patch_data_17[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748808, patch_data_17, 4);
	uint8_t patch_data_18[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007488cc, patch_data_18, 4);
	uint8_t patch_data_19[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748990, patch_data_19, 4);
	uint8_t patch_data_20[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748a54, patch_data_20, 4);
	uint8_t patch_data_21[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748b18, patch_data_21, 4);
	uint8_t patch_data_22[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748bdc, patch_data_22, 4);
	uint8_t patch_data_23[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748ca0, patch_data_23, 4);
	uint8_t patch_data_24[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748d64, patch_data_24, 4);
	uint8_t patch_data_25[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748e28, patch_data_25, 4);
	uint8_t patch_data_26[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748eec, patch_data_26, 4);
	uint8_t patch_data_27[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100748fb0, patch_data_27, 4);
	uint8_t patch_data_28[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749074, patch_data_28, 4);
	uint8_t patch_data_29[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749138, patch_data_29, 4);
	uint8_t patch_data_30[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007491fc, patch_data_30, 4);
	uint8_t patch_data_31[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007492c0, patch_data_31, 4);
	uint8_t patch_data_32[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749384, patch_data_32, 4);
	uint8_t patch_data_33[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749448, patch_data_33, 4);
	uint8_t patch_data_34[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074950c, patch_data_34, 4);
	uint8_t patch_data_35[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007495d0, patch_data_35, 4);
	uint8_t patch_data_36[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749694, patch_data_36, 4);
	uint8_t patch_data_37[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749758, patch_data_37, 4);
	uint8_t patch_data_38[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074981c, patch_data_38, 4);
	uint8_t patch_data_39[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007498e0, patch_data_39, 4);
	uint8_t patch_data_40[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x1007499a4, patch_data_40, 4);
	uint8_t patch_data_41[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749a68, patch_data_41, 4);
	uint8_t patch_data_42[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749b2c, patch_data_42, 4);
	uint8_t patch_data_43[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749bf0, patch_data_43, 4);
	uint8_t patch_data_44[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749cb4, patch_data_44, 4);
	uint8_t patch_data_45[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749d78, patch_data_45, 4);
	uint8_t patch_data_46[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749e3c, patch_data_46, 4);
	uint8_t patch_data_47[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749f00, patch_data_47, 4);
	uint8_t patch_data_48[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x100749fc4, patch_data_48, 4);
	uint8_t patch_data_49[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a088, patch_data_49, 4);
	uint8_t patch_data_50[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a14c, patch_data_50, 4);
	uint8_t patch_data_51[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a210, patch_data_51, 4);
	uint8_t patch_data_52[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a2d4, patch_data_52, 4);
	uint8_t patch_data_53[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a398, patch_data_53, 4);
	uint8_t patch_data_54[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a45c, patch_data_54, 4);
	uint8_t patch_data_55[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a520, patch_data_55, 4);
	uint8_t patch_data_56[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a5e4, patch_data_56, 4);
	uint8_t patch_data_57[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a6a8, patch_data_57, 4);
	uint8_t patch_data_58[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a76c, patch_data_58, 4);
	uint8_t patch_data_59[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a830, patch_data_59, 4);
	uint8_t patch_data_60[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a8f4, patch_data_60, 4);
	uint8_t patch_data_61[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074a9b8, patch_data_61, 4);
	uint8_t patch_data_62[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074aa7c, patch_data_62, 4);
	uint8_t patch_data_63[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074ab40, patch_data_63, 4);
	uint8_t patch_data_64[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074ac04, patch_data_64, 4);
	uint8_t patch_data_65[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074acc8, patch_data_65, 4);
	uint8_t patch_data_66[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074ad8c, patch_data_66, 4);
	uint8_t patch_data_67[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074ae50, patch_data_67, 4);
	uint8_t patch_data_68[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074af14, patch_data_68, 4);
	uint8_t patch_data_69[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074afd8, patch_data_69, 4);
	uint8_t patch_data_70[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b09c, patch_data_70, 4);
	uint8_t patch_data_71[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b160, patch_data_71, 4);
	uint8_t patch_data_72[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b224, patch_data_72, 4);
	uint8_t patch_data_73[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b2e8, patch_data_73, 4);
	uint8_t patch_data_74[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b3ac, patch_data_74, 4);
	uint8_t patch_data_75[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b474, patch_data_75, 4);
	uint8_t patch_data_76[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b540, patch_data_76, 4);
	uint8_t patch_data_77[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b604, patch_data_77, 4);
	uint8_t patch_data_78[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b6c8, patch_data_78, 4);
	uint8_t patch_data_79[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b78c, patch_data_79, 4);
	uint8_t patch_data_80[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b850, patch_data_80, 4);
	uint8_t patch_data_81[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b914, patch_data_81, 4);
	uint8_t patch_data_82[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074b9d8, patch_data_82, 4);
	uint8_t patch_data_83[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074ba9c, patch_data_83, 4);
	uint8_t patch_data_84[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074bb60, patch_data_84, 4);
	uint8_t patch_data_85[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074bc28, patch_data_85, 4);
	uint8_t patch_data_86[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074bcf4, patch_data_86, 4);
	uint8_t patch_data_87[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074bdb8, patch_data_87, 4);
	uint8_t patch_data_88[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074be7c, patch_data_88, 4);
	uint8_t patch_data_89[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074bf40, patch_data_89, 4);
	uint8_t patch_data_90[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c004, patch_data_90, 4);
	uint8_t patch_data_91[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c0c8, patch_data_91, 4);
	uint8_t patch_data_92[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c18c, patch_data_92, 4);
	uint8_t patch_data_93[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c250, patch_data_93, 4);
	uint8_t patch_data_94[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c314, patch_data_94, 4);
	uint8_t patch_data_95[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c3d8, patch_data_95, 4);
	uint8_t patch_data_96[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c49c, patch_data_96, 4);
	uint8_t patch_data_97[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c560, patch_data_97, 4);
	uint8_t patch_data_98[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c624, patch_data_98, 4);
	uint8_t patch_data_99[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c6e8, patch_data_99, 4);
	uint8_t patch_data_100[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c7ac, patch_data_100, 4);
	uint8_t patch_data_101[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c870, patch_data_101, 4);
	uint8_t patch_data_102[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c934, patch_data_102, 4);
	uint8_t patch_data_103[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074c9f8, patch_data_103, 4);
	uint8_t patch_data_104[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074cabc, patch_data_104, 4);
	uint8_t patch_data_105[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074cb80, patch_data_105, 4);
	uint8_t patch_data_106[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074cc44, patch_data_106, 4);
	uint8_t patch_data_107[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074cd08, patch_data_107, 4);
	uint8_t patch_data_108[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074cdcc, patch_data_108, 4);
	uint8_t patch_data_109[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074ce90, patch_data_109, 4);
	uint8_t patch_data_110[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074cf54, patch_data_110, 4);
	uint8_t patch_data_111[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d018, patch_data_111, 4);
	uint8_t patch_data_112[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d0dc, patch_data_112, 4);
	uint8_t patch_data_113[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d1a0, patch_data_113, 4);
	uint8_t patch_data_114[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d264, patch_data_114, 4);
	uint8_t patch_data_115[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d328, patch_data_115, 4);
	uint8_t patch_data_116[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d3ec, patch_data_116, 4);
	uint8_t patch_data_117[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d4b0, patch_data_117, 4);
	uint8_t patch_data_118[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d574, patch_data_118, 4);
	uint8_t patch_data_119[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d638, patch_data_119, 4);
	uint8_t patch_data_120[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d6fc, patch_data_120, 4);
	uint8_t patch_data_121[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d7c0, patch_data_121, 4);
	uint8_t patch_data_122[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d884, patch_data_122, 4);
	uint8_t patch_data_123[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074d948, patch_data_123, 4);
	uint8_t patch_data_124[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074da0c, patch_data_124, 4);
	uint8_t patch_data_125[] = {0xb5, 0x22, 0x41, 0xf9};
	patch(0x10074dae4, patch_data_125, 4);
	uint8_t patch_data_126[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x100756538, patch_data_126, 4);
	uint8_t patch_data_127[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100756728, patch_data_127, 4);
	uint8_t patch_data_128[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x1007567c4, patch_data_128, 4);
	uint8_t patch_data_129[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100756860, patch_data_129, 4);
	uint8_t patch_data_130[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100756908, patch_data_130, 4);
	uint8_t patch_data_131[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x1007569c0, patch_data_131, 4);
	uint8_t patch_data_132[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100756a78, patch_data_132, 4);
	uint8_t patch_data_133[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100756b44, patch_data_133, 4);
	uint8_t patch_data_134[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x100756c88, patch_data_134, 4);
	uint8_t patch_data_135[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x100756d50, patch_data_135, 4);
	uint8_t patch_data_136[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x100756ee4, patch_data_136, 4);
	uint8_t patch_data_137[] = {0x4a, 0x21, 0x41, 0xf9};
	patch(0x100757a5c, patch_data_137, 4);
	uint8_t patch_data_138[] = {0x29, 0x21, 0x41, 0xf9};
	patch(0x10075937c, patch_data_138, 4);
	uint8_t patch_data_139[] = {0x7b, 0x23, 0x41, 0xf9};
	patch(0x10076cc40, patch_data_139, 4);
	uint8_t patch_data_140[] = {0x8, 0x21, 0x41, 0xf9};
	patch(0x10078cb98, patch_data_140, 4);
	uint8_t patch_data_141[] = {0x7b, 0x23, 0x41, 0xf9};
	patch(0x10078d38c, patch_data_141, 4);
}

void patchItemLimit() {
    // 0x100756c70(0x102e500)  ItemInstance::ItemInstance(int, int, int)
    uint8_t patch_1[] = { 0x3f, 0x10, 0x40, 0x71 };
    patch(0x100756C7C, patch_1, 4);
    // 0x100756d24(0x102e5a0)  ItemInstance::ItemInstance(int, int, int, CompoundTag const*)
    uint8_t patch_2[] = { 0x3f, 0x10, 0x40, 0x71 };
    patch(0x100756D44, patch_2, 4);
    // 0x100756e7c(0x102e684)  ItemInstance::ItemInstance(ItemInstance const&)
    uint8_t patch_3[] = { 0x1f, 0x11, 0x40, 0x71 };
    patch(0x100756ED8, patch_3, 4);
    // 0x1007569a4(0x102e2e4)  ItemInstance::ItemInstance(Item const*, int)
    uint8_t patch_4[] = { 0x1f, 0x11, 0x40, 0x71 };
    patch(0x1007569B4, patch_4, 4);
    // 0x100756b14(0x102e420)  ItemInstance::ItemInstance(Item const*, int, int, CompoundTag const*)
    uint8_t patch_5[] = { 0x1f, 0x11, 0x40, 0x71 };
    patch(0x100756B38, patch_5, 4);
    // 0x1007568E8             ItemInstance::ItemInstance(Item const*)
    uint8_t patch_6[] = { 0x1f, 0x11, 0x40, 0x71 };
    patch(0x1007568FC, patch_6, 4);
    // 0x100756A5C             ItemInstance::ItemInstance(Item const*, int, int)
    uint8_t patch_7[] = { 0x1f, 0x11, 0x40, 0x71 };
    patch(0x100756A6C, patch_7, 4);
    // 0x100758EAC             ItemInstance::load
    uint8_t patch_8[] = { 0x3f, 0x05, 0x40, 0x71 };
    patch(0x100759370, patch_8, 4);
}

static void (*_ItemRenderer$createSingleton)(void* textureGroup);
static void ItemRenderer$createSingleton(void* textureGroup) {
        _ItemRenderer$createSingleton(textureGroup);

        ItemRenderer$mItemGraphics->resize(4096);

        for(int i = 512; i < 4096; i++) {
        	(*ItemRenderer$mItemGraphics)[i] = (*ItemRenderer$mItemGraphics)[256];
        }
}

%ctor {
	initPatch();
	patchItemPtr();
	patchItemLimit();
	applyPatches();
  	Item$mItems = (Item***)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));
	Item$mItems[1] = new Item*[4096];
	memset(Item$mItems[1], 0, sizeof(Item*) * 4096);

	ItemRenderer$mItemGraphics = (std::vector<ItemGraphics>*)(0x10126b4e8 + _dyld_get_image_vmaddr_slide(0));

	MSHookFunction((void*)(0x1003cc458 + _dyld_get_image_vmaddr_slide(0)), (void*)&ItemRenderer$createSingleton, (void**)&_ItemRenderer$createSingleton);
}
