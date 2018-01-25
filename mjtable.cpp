//编译成so文件命令
//g++ mjtable.cpp -fPIC -std=c++11 -shared -o mjtable.so

extern "C"
{
#include <stdio.h>
#include <math.h>
#include <stdarg.h>
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <string.h>
}
#include <set>
#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <unordered_map>
// #include <chrono>

#define BYTE 						unsigned char
#define DWORD 						unsigned long
#define max(a,b)            (((a) > (b)) ? (a) : (b))

using namespace std;

namespace ArrayMJ
{
#define MAX_TOTAL_TYPE				34
#define MAX_VAL_NUM					9
#define MAX_KEY_NUM					(MAX_VAL_NUM+1)		//9+赖子
#define MAX_NAI_NUM					4				    //赖子最大个数
#define BIT_VAL_NUM					3				    //一个值占的bit数
#define BIT_VAL_FLAG				0x07				//

	//麻将颜色（种类）定义
	enum enColorMJ
	{
		enColorMJ_WAN = 0,  //万
		enColorMJ_TONG,     //筒
		enColorMJ_TIAO,     //条
		enColorMJ_FenZi,    //风、字 牌
		enColorMJ_Max,
	};

	set<int>							g_setSingle;		//单个顺子+刻子		50个
	set<int>							g_setSingleFZ;		//单个顺子+刻子		22个
	set<int>							g_setSingleJiang;	//单个将			19个
	set<int>							g_setSingleJiangFZ;	//单个将			15个

	BYTE								g_byArray[262144];
	BYTE								g_byArrayFZ[262144];
	BYTE								g_byError[262144];

	unordered_map<int, BYTE>			g_mapHuAll[15];
	unordered_map<int, BYTE>			g_mapHuAllFZ[15];

	inline int getKeyByIndex(BYTE byIndex[MAX_KEY_NUM], BYTE byNum = MAX_KEY_NUM)
	{
		int nKey = 0;
		for (int i = 0; i < byNum; ++i)
			nKey |= (int)(byIndex[i] & BIT_VAL_FLAG) << (BIT_VAL_NUM*i);
		return nKey;
	}
	inline int getArrayIndex(BYTE byIndex[MAX_VAL_NUM], BYTE byNum = MAX_VAL_NUM)
	{
		int nKey = 0;
		for (int i = 0; i < byNum; ++i)
		{
			if ((byIndex[i] & BIT_VAL_FLAG) > 3) byIndex[i] -= 3;
			nKey |= (int)(byIndex[i] & 0x03) << (2 * i);
		}
		return nKey;
	}
	inline int getArrayIndex(int llVal)
	{
		BYTE byIndex[MAX_VAL_NUM] = {};
		for (int i = 0; i < MAX_VAL_NUM; ++i)
			byIndex[i] = (llVal >> (BIT_VAL_NUM*i))&BIT_VAL_FLAG;

		return getArrayIndex(byIndex);
	}
	inline bool isValidKey(int llVal)
	{
		BYTE byIndex[MAX_KEY_NUM] = {};
		for (int i = 0; i < MAX_KEY_NUM; ++i)
			byIndex[i] = (llVal >> (BIT_VAL_NUM*i))&BIT_VAL_FLAG;

		if (byIndex[9] > MAX_NAI_NUM)	return false;
		int nNum = 0;
		for (int i = 0; i < MAX_KEY_NUM; ++i)
		{
			nNum += byIndex[i];
			if (byIndex[i] > 4 || nNum > 14)	//
				return false;
		}
		return nNum > 0;
	}
	inline BYTE getNumByKey(int llVal, BYTE byNum = MAX_KEY_NUM)
	{
		BYTE byIndex[MAX_KEY_NUM] = {};
		for (int i = 0; i < MAX_KEY_NUM; ++i)
			byIndex[i] = (llVal >> (BIT_VAL_NUM*i))&BIT_VAL_FLAG;

		BYTE nNum = 0;
		for (int i = 0; i < byNum; ++i)
			nNum += byIndex[i];
		return nNum;
	}
	inline void addMap(unordered_map<int, BYTE> mapTemp[], int llVal)
	{
		BYTE nNum = getNumByKey(llVal, MAX_VAL_NUM);
		BYTE byNum = (llVal >> (BIT_VAL_NUM * 9))&BIT_VAL_FLAG;
		int  val = (llVal & 0x7FFFFFF);
		unordered_map<int, BYTE>::iterator iter = mapTemp[nNum].find(val);
		if (iter != mapTemp[nNum].end())
			iter->second = min(byNum, iter->second);
		else
			mapTemp[nNum][val] = byNum;
	}

	class CHuPaiArrayMJ
	{
	private:
		static void TrainSingle()
		{
			BYTE byTemp[MAX_KEY_NUM] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 3 };
			g_setSingle.insert(getKeyByIndex(byTemp));
			g_setSingleFZ.insert(getKeyByIndex(byTemp));
			// 1.1 刻子
			for (int i = 0; i < MAX_VAL_NUM; ++i)
			{
				memset(byTemp, 0, MAX_KEY_NUM);
				for (int n = 0; n < 3; ++n)
				{
					byTemp[i] = 3 - n;	byTemp[9] = n;
					g_setSingle.insert(getKeyByIndex(byTemp));
					if (i < 7)	//风、字牌最多7张
						g_setSingleFZ.insert(getKeyByIndex(byTemp));
				}
			}
			// 1.2 顺子 没赖子
			for (int i = 0; i < MAX_VAL_NUM - 2; ++i)
			{
				memset(byTemp, 0, MAX_KEY_NUM);
				byTemp[i] = 1;	byTemp[i + 1] = 1;	byTemp[i + 2] = 1;
				g_setSingle.insert(getKeyByIndex(byTemp));
			}
			// 1.3 顺子 1个赖子 (2个赖子时也就是刻子)
			for (int i = 0; i < MAX_VAL_NUM - 2; ++i)
			{
				for (int n = 0; n < 3; ++n)
				{
					memset(byTemp, 0, MAX_KEY_NUM);
					byTemp[i] = 1;	byTemp[i + 1] = 1;	byTemp[i + 2] = 1;
					byTemp[i + n] = 0;	byTemp[9] = 1;
					g_setSingle.insert(getKeyByIndex(byTemp));
				}
			}
			// 2.1 将牌
			memset(byTemp, 0, MAX_KEY_NUM);
			byTemp[9] = 2;
			g_setSingleJiang.insert(getKeyByIndex(byTemp));
			g_setSingleJiangFZ.insert(getKeyByIndex(byTemp));
			for (int i = 0; i < MAX_VAL_NUM; ++i)
			{
				memset(byTemp, 0, MAX_KEY_NUM);
				for (int n = 0; n < 2; ++n)
				{
					byTemp[i] = 2 - n;	byTemp[9] = n;
					g_setSingleJiang.insert(getKeyByIndex(byTemp));
					if (i < 7)	//风、字牌最多7张
						g_setSingleJiangFZ.insert(getKeyByIndex(byTemp));
				}
			}
		};

		static void TrainAllComb(const set<int> &setSingle, unordered_map<int, BYTE> mapOut[])
		{
			int nAll = 0;
			int nSingle[100] = {};
			set<int>::iterator iter = setSingle.begin();
			for (; iter != setSingle.end(); ++iter)
				nSingle[nAll++] = *iter;

			for (int i1 = 0; i1 < nAll; ++i1)
			{
				addMap(mapOut, nSingle[i1]);
				for (int i2 = i1; i2 < nAll; ++i2)
				{
					int nTemp = nSingle[i1] + nSingle[i2];
					if (!isValidKey(nTemp))	continue;
					addMap(mapOut, nTemp);
					for (int i3 = i2; i3 < nAll; ++i3)
					{
						int nTemp = nSingle[i1] + nSingle[i2] + nSingle[i3];
						if (!isValidKey(nTemp))	continue;
						addMap(mapOut, nTemp);
						for (int i4 = i3; i4 < nAll; ++i4)
						{
							int nTemp = nSingle[i1] + nSingle[i2] + nSingle[i3] + nSingle[i4];
							if (!isValidKey(nTemp))	continue;
							addMap(mapOut, nTemp);
						}
					}
				}
			}
		}

		static void TrainAllComb_Jiang(const set<int> &setSingle, unordered_map<int, BYTE> mapOut[])
		{
			int nAll = 0;
			int nSingle[100] = {};

			set<int>::iterator iter = setSingle.begin();
			for (; iter != setSingle.end(); ++iter)
				nSingle[nAll++] = *iter;

			unordered_map<int, BYTE> mapTemp[15];
			for (int j = 0; j < 15; ++j)
				mapTemp[j] = mapOut[j];

			for (int i = 0; i < nAll; ++i)
			{
				for (int j = 0; j < 15; ++j)
				{
					addMap(mapOut, nSingle[i]);
					unordered_map<int, BYTE>::iterator iter_u = mapTemp[j].begin();
					for (; iter_u != mapTemp[j].end(); ++iter_u)
					{
						int nTemp = nSingle[i] + iter_u->first + (int(iter_u->second & BIT_VAL_FLAG) << 27);
						if (isValidKey(nTemp))
							addMap(mapOut, nTemp);
					}
				}
			}
		}

	public:
		static void TrainAll()
		{
			if (g_setSingle.empty())
			{
				memset(g_byArray, 0, sizeof(g_byArray));
				memset(g_byArrayFZ, 0, sizeof(g_byArrayFZ));
				memset(g_byError, 0, sizeof(g_byError));

				// DWORD dwFlag = GetTickCount();
				TrainSingle();
				TrainAllComb(g_setSingle, g_mapHuAll);
				TrainAllComb(g_setSingleFZ, g_mapHuAllFZ);
				TrainAllComb_Jiang(g_setSingleJiang, g_mapHuAll);
				TrainAllComb_Jiang(g_setSingleJiangFZ, g_mapHuAllFZ);

				int numAll = 0;
				for (int i = 0; i < 15; ++i)
				{
					numAll += g_mapHuAll[i].size();
					numAll += g_mapHuAllFZ[i].size();
				}
				// cout << "train cost:" << GetTickCount() - dwFlag << "ms numAll=" << numAll << endl;
				for (int i = 0; i < 15; ++i)
				{
					unordered_map<int, BYTE>::iterator iter = g_mapHuAll[i].begin();
					for (; iter != g_mapHuAll[i].end(); ++iter)
					{
						int nArrayIndex = getArrayIndex(iter->first);
						ArrayMJ::g_byArray[nArrayIndex] = max(ArrayMJ::g_byArray[nArrayIndex], iter->second + 1);
					}
					iter = g_mapHuAllFZ[i].begin();
					for (; iter != g_mapHuAllFZ[i].end(); ++iter)
					{
						int nArrayIndex = getArrayIndex(iter->first);
						ArrayMJ::g_byArrayFZ[nArrayIndex] = max(ArrayMJ::g_byArrayFZ[nArrayIndex], iter->second + 1);
					}
					g_mapHuAllFZ[i].clear();
				}

				for (int n = 0; n < sizeof(g_byArray); ++n)
				{
					int nNum = 0;
					BYTE byIndex[MAX_VAL_NUM] = {};
					for (int i = 0; i < MAX_VAL_NUM; ++i)
					{
						byIndex[i] = (n >> (2 * i)) & 0x03;
						nNum += byIndex[i];
					}
					if (nNum >= 15) continue;

					int nVal = getKeyByIndex(byIndex, MAX_VAL_NUM);
					unordered_map<int, BYTE>::iterator iter = g_mapHuAll[nNum].find(nVal);
					if (iter == g_mapHuAll[nNum].end())
						g_byError[n] = 1;
				}
				for (int i = 0; i < 15; ++i)
					g_mapHuAll[i].clear();

				/*
				// just show info
				int nZero = 0, nZeroFZ = 0, nError = 0, nAll = 0;
				for (int i = 0; i < sizeof(g_byArray); ++i)
				{
				int nNum = 0;
				BYTE byIndex[MAX_VAL_NUM] = {};
				for (int n = 0; n < MAX_VAL_NUM; ++n)
				{
				byIndex[n] = (i >> (2 * n)) & 0x03;
				nNum += byIndex[n];
				}
				if (nNum >= 15) continue;

				++nAll;
				if (g_byArray[i] == 0) ++nZero;
				if (g_byArrayFZ[i] == 0) ++nZeroFZ;
				if (g_byError[i] == 0) ++nError;
				}
				cout << "nAll = " << nAll << endl;
				cout << "nZero = " << nAll - nZero << " / " << nZero << endl;
				cout << "nZeroFZ = " << nAll - nZeroFZ << " / " << nZeroFZ << endl;
				cout << "nError = " << nAll - nError << " / " << nError << endl;
				//*/
			}
			else
				cout << "already trained!" << endl;
		}

		static bool CheckCanHu(BYTE byCardSrc[], BYTE byNaiIndex)
		{
			BYTE byCards[MAX_TOTAL_TYPE];
			memcpy(byCards, byCardSrc, MAX_TOTAL_TYPE);
			int nNaiZiNum = 0;
			if (byNaiIndex < MAX_TOTAL_TYPE)
			{
				nNaiZiNum = byCards[byNaiIndex];
				byCards[byNaiIndex] = 0;
			}

			BYTE byJiangNum = 0;
			BYTE nNaiTry;
			for (int cor = 0; cor < enColorMJ_Max; ++cor)
			{
				int nMax = (cor == enColorMJ_FenZi) ? 7 : 9;
				int nVal = 0, nNum = 0;
				BYTE byDelIndex = 0xFF, byTemp = 0;
				for (int i = 0; i < nMax; ++i)
				{
					byTemp = byCards[9 * cor + i];
					nNum += byTemp;
					if (byTemp > 3)
					{
						byDelIndex = i;
						nVal |= (int)(byTemp - 3) << (2 * i);
					}
					else
						nVal |= (int)(byTemp) << (2 * i);
				}

				if (nNum == 0) continue;

				if (g_byError[nVal]) return false;

				nNaiTry = (cor == enColorMJ_FenZi) ? g_byArrayFZ[nVal] - 1 : g_byArray[nVal] - 1;
				if (nNaiTry != 0xFF)
					byJiangNum += ((nNum + nNaiTry) % 3 == 2);

				if (nNaiTry == 0xFF || nNaiZiNum < nNaiTry || byJiangNum + nNaiTry > nNaiZiNum + 1)
				{
					if (byDelIndex != 0xFF)
					{
						byCards[9 * cor + byDelIndex] -= 2;
						--cor; ++byJiangNum;
						continue;
					}
					return false;
				}
				nNaiZiNum -= nNaiTry;
			}
			return byJiangNum > 0 || nNaiZiNum >= 2;
		}
	};
}

#define	MASK_COLOR					0xF0			    //花色掩码
#define	MASK_VALUE					0x0F			    //数值掩码

static BYTE g_HuCardAll[136];
ArrayMJ::CHuPaiArrayMJ stArray;

//扑克转换---转换实际的牌值数据
static BYTE SwitchToCardData(BYTE cbCardIndex)
{
	return ((cbCardIndex / 9) << 4) | (cbCardIndex % 9 + 1);
}

//扑克转换---转换为索引
static BYTE SwitchToCardIndex(BYTE cbCardData)
{
	return ((cbCardData&MASK_COLOR) >> 4) * 9 + (cbCardData&MASK_VALUE) - 1;
}

static int l_init(lua_State *L)
{
	stArray.TrainAll();
    // printf("Finish TrainAll()\n");
	lua_pushnumber(L, 1);  /* push result */
    /* 这里可以看出，C可以返回给Lua多个结果，
     * 通过多次调用lua_push*()，之后return返回结果的数量。
     */
    return 1;  /* number of results */
}

/* 所有注册给Lua的C函数具有
 * "typedef int (*lua_CFunction) (lua_State *L);"的原型。
 */
static int l_hupai(lua_State *L)
{
    
    // 如果给定虚拟栈中索引处的元素可以转换为数字，则返回转换后的数字，否则报错。
    BYTE cardIndex[34];
    memset(cardIndex, 0, sizeof(cardIndex));
    
    // int size = lua_gettop(L);//相当于#table
    // printf("size = %d\n", size);
    BYTE guiCard = luaL_checknumber(L, -1);
    BYTE guiIndex = SwitchToCardIndex(guiCard);
    // printf("guiIndex = %d\n", guiIndex);
    lua_remove(L, -1);
    // lua_pop(L, -1);
    // size = lua_gettop(L);//相当于#table
    // printf("size = %d\n", size);
    int rawlen = lua_rawlen(L, -1); // 打印该变量的长度
    // printf("rawlen = %d\n", rawlen);
    for (int i = 0; i < rawlen; i++)
    {
        // lua_rawgeti
        // void lua_rawgeti (lua_State *L, int index, int n);
        // 把 t[n] 的值压栈，这里的 t 是指给定索引 index 处的一个值。这是一个直接访问；就是说，它不会触发元方法。
        lua_rawgeti(L, -1, i + 1);
        // size = lua_gettop(L);//相当于#table
        // printf("size = %d\n", size);
        BYTE card = luaL_checknumber(L, -1);
        // printf("card is %d\n", card);
        cardIndex[SwitchToCardIndex(card)]++;
        lua_remove(L, -1);
        // printf("cardIndex[%d] = %d\n", SwitchToCardIndex(card), cardIndex[SwitchToCardIndex(card)]);
    }
    lua_remove(L, -1);
    // size = lua_gettop(L);//相当于#table
    // printf("size = %d\n", size);

    int ishu = stArray.CheckCanHu(cardIndex, guiIndex);

    // printf("begin!\n");
    // auto start = chrono::system_clock::now();  

    // int ishu = 0;
    // for(int i = 0; i < 1000000; i++)
    // {
    //     ishu = stArray.CheckCanHu(cardIndex, guiIndex);
    // }

    // auto end = chrono::system_clock::now();
    // auto duration = chrono::duration_cast<chrono::microseconds>(end - start);
    // printf("hu 100W times duration is %lf\n", double(duration.count()) * chrono::microseconds::period::num / chrono::microseconds::period::den);

    // printf("ishu = %d\n", ishu);

    lua_pushnumber(L, ishu);  /* push result */

    /* 这里可以看出，C可以返回给Lua多个结果，
     * 通过多次调用lua_push*()，之后return返回结果的数量。
     */
    return 1;  /* number of results */
}

static int l_canhu(lua_State *L)
{   
    BYTE cardIndex[34];
    memset(cardIndex, 0, sizeof(cardIndex));
    BYTE guiCard = luaL_checknumber(L, -1);
    BYTE guiIndex = SwitchToCardIndex(guiCard);
    lua_remove(L, -1);
    int rawlen = lua_rawlen(L, -1);
    for (int i = 0; i < rawlen; i++)
    {
        lua_rawgeti(L, -1, i + 1);
        BYTE card = luaL_checknumber(L, -1);
        cardIndex[SwitchToCardIndex(card)]++;
        lua_remove(L, -1);
    }
    lua_remove(L, -1);

    vector<int> canhuvector;
    canhuvector.clear();
    for (int j = 0; j < 34; j++)
    {
        if (cardIndex[j] < 4)
        {
            cardIndex[j]++;
            int hu = stArray.CheckCanHu(cardIndex, guiIndex);
            if (hu == 1)
            {
                canhuvector.insert(canhuvector.begin(), j);
            }
            cardIndex[j]--;
        }
    }

    lua_newtable(L);
    if(canhuvector.size() > 0)
    {
        for(int i = 0; i < canhuvector.size(); i++)
        {
            lua_pushnumber(L, SwitchToCardData(canhuvector[i]));
            lua_rawseti(L, -2, i + 1);
        }
    }  

    return 1;
}
static int l_tinghu(lua_State *L)
{
    // 如果给定虚拟栈中索引处的元素可以转换为数字，则返回转换后的数字，否则报错。
    BYTE cardIndex[34];
    memset(cardIndex, 0, sizeof(cardIndex));
    // int size = lua_gettop(L);//相当于#table
    // printf("size = %d\n", size);
    BYTE guiCard = luaL_checknumber(L, -1);
    BYTE guiIndex = SwitchToCardIndex(guiCard);
    // printf("guiIndex = %d\n", guiIndex);
    lua_remove(L, -1);
    // lua_pop(L, -1);
    // size = lua_gettop(L);//相当于#table
    // printf("size = %d\n", size);
    int rawlen = lua_rawlen(L, -1); // 打印该变量的长度
    // printf("rawlen = %d\n", rawlen);
    for (int i = 0; i < rawlen; i++)
    {
        lua_rawgeti(L, -1, i + 1);
        // size = lua_gettop(L);//相当于#table
        // printf("size = %d\n", size);
        BYTE card = luaL_checknumber(L, -1);
        // printf("card is %d\n", card);
        cardIndex[SwitchToCardIndex(card)]++;
        lua_remove(L, -1);
        // printf("cardIndex[%d] = %d\n", i, cardIndex[i]);
    }
    lua_remove(L, -1);
    // int size = lua_gettop(L);//相当于#table
    // printf("size = %d\n", size);

    map<int, vector<int>> tingmap;
    for (int i = 0; i < 34; i++)
	{
		if (cardIndex[i] > 0)
		{
			cardIndex[i]--;
			vector<int>canhuvector;
			canhuvector.clear();
			for (int j = 0; j < 34; j++)
			{
				if (cardIndex[j] < 4)
				{
					cardIndex[j]++;
					int hu = stArray.CheckCanHu(cardIndex, guiIndex);
					if (hu == 1)
					{
						canhuvector.insert(canhuvector.begin(), j);
					}
					cardIndex[j]--;
				}
			}
			if (canhuvector.size() > 0)
			{
				tingmap.insert(pair<int, vector<int>>(i, canhuvector));
			}
			cardIndex[i]++;
		}
	}
    // int size = lua_gettop(L);
    // printf("size11111 = %d\n", size);
    lua_newtable(L);
    // size = lua_gettop(L);
    // printf("size22222 = %d\n", size);
    if(tingmap.size() > 0)
    {
        int index = 0;
        map<int, vector<int>>::iterator it_map = tingmap.begin();
        
        while(it_map != tingmap.end())
        {
            // size = lua_gettop(L);
            // printf("size33333 = %d\n", size);
            int tingcard = it_map->first;
            lua_pushnumber(L, SwitchToCardData(tingcard));
            // size = lua_gettop(L);
            // printf("size44444 = %d\n", size);
            lua_newtable(L);
            // size = lua_gettop(L);
            // printf("size55555 = %d\n", size);
            // printf("it_map->first = %d, it_map->second.size() = %d\n", (int)it_map->first, (int)it_map->second.size());
            for(int i = 0; i < it_map->second.size(); i++)
            {
                // size = lua_gettop(L);
                // printf("size66666 = %d\n", size);
                lua_pushnumber(L, SwitchToCardData((it_map->second)[i]));
                // printf(" (it_map->second)[%d] = %d\n", i, (it_map->second)[i]);
                // lua_rawset(L, -3);
                // size = lua_gettop(L);
                // printf("size77777 = %d\n", size);
                // lua_rawseti
                // 原型: void lua_rawseti (lua_State *L, int index, int n); 
                // 描述: 为table中的key赋值. t[n] = v .其中t是index处的table , v为栈顶元素. 
                //     这个函数不会触发newindex元方法. 
                //     调用完成后弹出栈顶元素. 
                lua_rawseti(L, -2, i + 1);
                // size = lua_gettop(L);
                // printf("size88888 = %d\n", size);
            }
            // size = lua_gettop(L);
            // printf("size99999 = %d\n", size);
            // lua_settable
            // void lua_settable (lua_State *L, int index);
            // 作一个等价于 t[k] = v 的操作， 这里 t 是一个给定有效索引 index 处的值， v 指栈顶的值， 而 k 是栈顶之下的那个值。
            // 这个函数会把键和值都从堆栈中弹出。
            // 其实这个解释的意思就是，lua_settable 会把栈顶作为value,栈顶的下一个作为key设置到index指向的table，最后把这两个弹出弹出栈，这时候settable完成。
            // lua_rawset
            // 用法同lua_settable,但更快(因为当key不存在时不用访问元方法__newindex)
            lua_rawset(L, -3);
            // size = lua_gettop(L);
            // printf("size00000 = %d\n", size);
            index++;
            it_map++;
        }
    }
    // lua_newtable(L);//创建一个表格，放在栈顶  
    // lua_pushstring(L, "mydata");//压入key  
    // lua_pushnumber(L,66);//压入value  
    // lua_settable(L,-3);//弹出key,value，并设置到table里面去  
    
    // lua_pushstring(L, "subdata");//压入key  
    // lua_newtable(L);//压入value,也是一个table  
    // lua_pushstring(L, "mydata");//压入subtable的key  
    // lua_pushnumber(L,53);//value  
    // lua_settable(L,-3);//弹出key,value,并设置到subtable  
    
    // lua_settable(L,-3);//这时候父table的位置还是-3,弹出key,value(subtable),并设置到table里去  
    // lua_pushstring(L, "mydata2");//同上  
    // lua_pushnumber(L,77);  
    // lua_settable(L,-3);  
    // return 1;//堆栈里现在就一个table.其他都被弹掉了。  

    return 1;  /* number of results */
}

/* 需要一个"luaL_Reg"类型的结构体，其中每一个元素对应一个提供给Lua的函数。
 * 每一个元素中包含此函数在Lua中的名字，以及该函数在C库中的函数指针。
 * 最后一个元素为“哨兵元素”（两个"NULL"），用于告诉Lua没有其他的函数需要注册。
 */
static const struct luaL_Reg mjtable[] = {
	{"init", l_init},
    {"hupai", l_hupai},
    {"canhu", l_canhu},
    {"tinghu", l_tinghu},
    {NULL, NULL}
};

/* 此函数为C库中的“特殊函数”。
 * 通过调用它注册所有C库中的函数，并将它们存储在适当的位置。
 * 此函数的命名规则应遵循：
 * 1、使用"luaopen_"作为前缀。
 * 2、前缀之后的名字将作为"require"的参数。
 */
extern "C" int luaopen_mjtable(lua_State* L)
{
    /* void luaL_newlib (lua_State *L, const luaL_Reg l[]);
     * 创建一个新的"table"，并将"l"中所列出的函数注册为"table"的域。
     */ 
    luaL_newlib(L, mjtable);

    return 1;
}