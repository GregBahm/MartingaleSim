Shader "Custom/LabelBackplateShader" 
{
	Properties 
    {
		_Color ("Color", Color) = (1,1,1,1)
		_AdditionalEmissive ("Additional Emissive", Color) = (1,1,1,1)
		_ClippedColor ("Clipped Color", Color) = (1,1,1,1)
		_BorderColor ("Border Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader 
    {
        
        Tags {"Queue" = "Transparent" "RenderType"="Transparent" }
		LOD 200
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows alpha:fade 
        #pragma target 3.0

		sampler2D _MainTex;

		struct Input 
        {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		fixed4 _BorderColor;
		fixed4 _AdditionalEmissive;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

        float GetBorderFadeBasis(float2 uvs)
        {
            float xDist = .5 - abs(uvs.x - .5);
            xDist *= 300;

            float yDist = .5 - abs(uvs.y - .5);
            yDist *= 150;
            float border = min(xDist, yDist);
            return border;
        }
        
		void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            float borderFadeBasis = GetBorderFadeBasis(IN.uv_MainTex);
            float borderFade = pow(saturate(borderFadeBasis / 50), .2);

			o.Albedo = _Color;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
            o.Emission = _AdditionalEmissive;
            o.Alpha = .9 * borderFade;
		}
		ENDCG

        ZTest Greater
		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows alpha:fade 
        #pragma target 3.0

		sampler2D _MainTex;

		struct Input 
        {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _ClippedColor;
		fixed4 _BorderColor;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

        float GetBorderFadeBasis(float2 uvs)
        {
            float xDist = .5 - abs(uvs.x - .5);
            xDist *= 300;

            float yDist = .5 - abs(uvs.y - .5);
            yDist *= 150;
            float border = min(xDist, yDist);
            return border;
        }
        
		void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            float borderFadeBasis = GetBorderFadeBasis(IN.uv_MainTex);
			o.Albedo = _ClippedColor;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
            o.Alpha = pow(saturate(borderFadeBasis / 50), .2);
         }
		ENDCG
	}
	FallBack "Diffuse"
}
