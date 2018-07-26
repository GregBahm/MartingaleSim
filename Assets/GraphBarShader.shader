Shader "Unlit/GraphBarShader"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
        
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
            
            float _Selected;
            int _Row;
            int _RowSelected;
            int _Column;
            int _ColumnSelected;
            float _Boring;
            float _XGrid;
            float _ZGrid;
            float _Height;
            float _BaseHeight;
            float _Ratio;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 gridSpace : TEXCOORD4;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
                bool subSelected : TEXCOORD5;
			};
			
            bool GetIsSubselected()
            {
                return _Column == _ColumnSelected || _Row == _RowSelected; 
            }

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
                o.normal = v.normal;
				UNITY_TRANSFER_FOG(o,o.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.gridSpace = worldPos / float3(40, 60, 40);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{  
                //clip(_Selected - .5);
                float shade = dot(i.normal, float3(.5, -.5, -5));
                shade = shade / 2 + .5;
                shade = lerp(.7, 1, saturate(shade));
                float3 col = lerp(float3(1, 0, 0), float3(0, 1, 1), i.gridSpace.y);
                col = 0;
                
                float3 xColor = lerp(float3(1, 0, 0), .5, _XGrid);
                float3 zColor = lerp(float3(0, 0, 1), .5, _ZGrid);

                col += xColor * (abs(i.normal.x) + abs(i.normal.y));
                col += zColor * (abs(i.normal.z) + abs(i.normal.y));
                col = lerp(float3(1, .5, 0), float3(2, 1, .5), _Ratio * 2 - 1);
                
                bool tipTop = i.gridSpace.y > _BaseHeight;
                float3 boringColor =  shade / 2  + i.gridSpace.y / 2 + .2;

                bool truelyBoring = _Boring * tipTop;
                col = lerp(boringColor, col, truelyBoring + _Boring / 4);
				
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(col, 1);
			}
			ENDCG
		}
	}
            Fallback "Diffuse"
}
