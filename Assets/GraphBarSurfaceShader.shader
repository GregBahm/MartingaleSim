Shader "Custom/GraphBarSurfaceShader" {
	Properties {
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard vertex:vert fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		struct Input 
        {
            float3 gridSpace;
            float3 normal;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
            
        float _Selected;
        float _Boring;
        float _XGrid;
        float _ZGrid;
        float _Height;
        float _BaseHeight;
        float _Ratio;
        float3 _ColorA;
        float3 _ColorB;
        float3 _ColorC;
        float _FirstSurvives;
        float _SurvivalMode;
        float _Locked;
        
        int _Row;
        int _RowSelected;
        int _Column;
        int _ColumnSelected;
        
        bool GetIsSubselected()
        {
            return (_Column == _ColumnSelected || _Row == _RowSelected); 
        }

      void vert (inout appdata_full v, out Input o) 
      {
        float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
        o.gridSpace = worldPos / float3(40, 60, 40);
        o.normal = v.normal;
      }

      float3 GetColor(Input i)
      {
        float baseColChoiser = pow(saturate((_Ratio - .5) * 2), .2);
        float3 col = lerp(_ColorA, 0, baseColChoiser);
                
        bool tipTop = i.gridSpace.y > _BaseHeight;
        float3 boringColor =  0  + i.gridSpace.y / 2 + .2;
        float subSelect = GetIsSubselected();
        bool truelyBoring = _Boring * tipTop;
        col = lerp(0, col, truelyBoring + _Boring / 4);
        float3 survivalColor = lerp(_ColorB, _ColorC, _FirstSurvives);
        col = lerp(col, survivalColor, _SurvivalMode);
        col = lerp(col, 1, subSelect / 10);
        col = lerp(col, float3(2, .5, 0), _Selected);
        return col;
      }

		void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            float3 col = GetColor(IN);
			o.Albedo = col;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;

            float lockBump = _Selected * _Locked;
            o.Emission = pow(_Ratio, 5) * (1 - _SurvivalMode) + lockBump;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
