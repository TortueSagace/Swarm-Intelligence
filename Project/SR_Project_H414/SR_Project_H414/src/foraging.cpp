#include "foraging.h"

#include <argos3/plugins/simulator/entities/cylinder_entity.h>

#include <algorithm>
#include <cstring>
#include <cerrno>

/****************************************/
/****************************************/

static const Real OBJECT_RADIUS            = 0.1f;
static const Real OBJECT_DIAMETER          = OBJECT_RADIUS * 2.0f;

static const Real CONSTRUCTION_AREA_MIN_X  = 4.9f;
static const Real CONSTRUCTION_AREA_MAX_X  = 5.6f;
static const Real CONSTRUCTION_AREA_MIN_Y  = -1.625f;
static const Real CONSTRUCTION_AREA_MAX_Y  = 1.625f;

/****************************************/
/****************************************/

CForaging::CForaging() :
   m_fMinCacheX(3.0f),
   m_fMaxCacheX(3.35f),
   m_fMinCacheY(-1.625f), 
   m_fMaxCacheY(1.625f),
   m_fCacheValue(0.2f),
   m_fTargetValue(0.8f),
   m_cDarkGrayRange(0.05f, 0.55f),
   m_cLightGrayRange(0.50f, 0.90f),
   m_bResetAll(false),
   m_pcRNG(NULL) {
}

/****************************************/
/****************************************/

CForaging::~CForaging() {
   /* Nothing to do */
}

/****************************************/
/****************************************/

void CForaging::Init(TConfigurationNode& t_tree) {
   try {
      TConfigurationNode& tForaging = GetNode(t_tree, "params");

      /* Get the cache area configuration from XML */
      GetNodeAttribute(tForaging, "min_cache_x", m_fMinCacheX);
      GetNodeAttribute(tForaging, "max_cache_x", m_fMaxCacheX);
      GetNodeAttribute(tForaging, "min_cache_y", m_fMinCacheY);
      GetNodeAttribute(tForaging, "max_cache_y", m_fMaxCacheY);
      GetNodeAttribute(tForaging, "reset_all", m_bResetAll);
      
   }
   catch(CARGoSException& ex) {
      THROW_ARGOSEXCEPTION_NESTED("Error parsing loop functions!", ex);
   }

   m_pcRNG = CRandom::CreateRNG("argos");
   
   Real fFirstColor = m_pcRNG->Uniform(m_cDarkGrayRange);
   Real fSecondColor = m_pcRNG->Uniform(m_cLightGrayRange);

   if (fFirstColor == fSecondColor)
   {
      m_fCacheValue = 0.2f;
      m_fTargetValue = 0.8f;
   }
   else {
      if (fFirstColor > fSecondColor)
      {
         m_fCacheValue = fFirstColor;
         m_fTargetValue = fSecondColor;
      }
      else {
         m_fCacheValue = fSecondColor;
         m_fTargetValue = fFirstColor;
      }
   }
}

/****************************************/
/****************************************/

void CForaging::Reset() {
   /* Nothing to do */
   m_vecConstructionObjectsInArea.clear();

   if (m_bResetAll)
   {
      Real fFirstColor = m_pcRNG->Uniform(m_cDarkGrayRange);
      Real fSecondColor = m_pcRNG->Uniform(m_cLightGrayRange);

      if (fFirstColor == fSecondColor)
      {
         m_fCacheValue = 0.2f;
         m_fTargetValue = 0.8f;
      }
      else {
         if (fFirstColor > fSecondColor)
         {
            m_fCacheValue = fFirstColor;
            m_fTargetValue = fSecondColor;
         }
         else {
            m_fCacheValue = fSecondColor;
            m_fTargetValue = fFirstColor;
         }
      }

      MoveRobots();
   }
}

/****************************************/
/****************************************/

void CForaging::Destroy() {
   /* Nothing to do */
}

/****************************************/
/****************************************/

void CForaging::PreStep() {
   /* Nothing to do */
}

/****************************************/
/****************************************/

void CForaging::PostStep() {

}

/****************************************/
/****************************************/

void CForaging::PostExperiment() {
  FilterObjects();
  /* Output a line for this step */
  LOG << "Objects: " << m_vecConstructionObjectsInArea.size() << std::endl;
}

/****************************************/
/****************************************/

CColor CForaging::GetFloorColor(const CVector2& c_position_on_plane) {
   /* Check if the given point is within the construction area */
   if(c_position_on_plane.GetX() >= CONSTRUCTION_AREA_MIN_X &&
      c_position_on_plane.GetX() <= CONSTRUCTION_AREA_MAX_X &&
      c_position_on_plane.GetY() >= CONSTRUCTION_AREA_MIN_Y &&
      c_position_on_plane.GetY() <= CONSTRUCTION_AREA_MAX_Y) {
      /* Yes, it is - return darker gray */
      return CColor(m_fTargetValue*255, m_fTargetValue*255, m_fTargetValue*255);
   }

   /* Check if the given point is within the cache area */
   if(c_position_on_plane.GetX() >= m_fMinCacheX &&
      c_position_on_plane.GetX() <= m_fMaxCacheX &&
      c_position_on_plane.GetY() >= m_fMinCacheY &&
      c_position_on_plane.GetY() <= m_fMaxCacheY) {
      /* Yes, it is - return lighter gray */
      return CColor(m_fCacheValue*255, m_fCacheValue*255, m_fCacheValue*255);
   }

   /* No, it isn't - return white */
   return CColor::WHITE;
}

/****************************************/
/****************************************/

bool ObjectYCoordCompare(const CVector3& c_vec1,
                         const CVector3& c_vec2) {
   return c_vec1.GetY() < c_vec2.GetY();
}

void CForaging::FilterObjects() {
   /* Clear list of positions of objects in construction area */
   m_vecConstructionObjectsInArea.clear();

   /* Get the list of cylinders from the ARGoS space */
   CSpace::TMapPerType& tCylinderMap = GetSpace().GetEntitiesByType("cylinder");
   /* Go through the list and collect data */
   for(CSpace::TMapPerType::iterator it = tCylinderMap.begin();
       it != tCylinderMap.end();
       ++it) {
      /* Get a reference to the object body */
      CEmbodiedEntity& cBody = any_cast<CCylinderEntity*>(it->second)->GetEmbodiedEntity();
      /* Check if object is in target area */
      if(cBody.GetOriginAnchor().Position.GetX() > CONSTRUCTION_AREA_MIN_X &&
         cBody.GetOriginAnchor().Position.GetX() < CONSTRUCTION_AREA_MAX_X &&
         cBody.GetOriginAnchor().Position.GetY() > CONSTRUCTION_AREA_MIN_Y &&
         cBody.GetOriginAnchor().Position.GetY() < CONSTRUCTION_AREA_MAX_Y) {
         /* Yes, it is */
         /* Add it to the list */
         m_vecConstructionObjectsInArea.push_back(cBody.GetOriginAnchor().Position);
      }
   }

}

/****************************************/
/****************************************/

void CForaging::MoveRobots() {
  CFootBotEntity* pcFootBot;
  bool bPlaced = false;
  UInt32 unTrials;
  CSpace::TMapPerType& tFootBotMap = GetSpace().GetEntitiesByType("foot-bot");
  for (CSpace::TMapPerType::iterator it = tFootBotMap.begin(); it != tFootBotMap.end(); ++it) {
    pcFootBot = any_cast<CFootBotEntity*>(it->second);
    // Choose position at random
    unTrials = 0;
    do {
       ++unTrials;
       CVector3 cFootBotPosition = GetRandomPosition();
       bPlaced = MoveEntity(pcFootBot->GetEmbodiedEntity(),
                            cFootBotPosition,
                            CQuaternion().FromEulerAngles(m_pcRNG->Uniform(CRange<CRadians>(CRadians::ZERO,CRadians::TWO_PI)),
                            CRadians::ZERO,CRadians::ZERO),false);
    } while(!bPlaced && unTrials < 1000);
    if(!bPlaced) {
       THROW_ARGOSEXCEPTION("Can't place robot");
    }
  }
}

/****************************************/
/****************************************/

CVector3 CForaging::GetRandomPosition() {
  Real temp;
  Real fPoseX = m_pcRNG->Uniform(CRange<Real>(1.5f, 5.5f));
  Real fPoseY = m_pcRNG->Uniform(CRange<Real>(-2.0f, 2.0f));

  return CVector3(fPoseX, fPoseY, 0);
}

/****************************************/
/****************************************/

/* Register this loop functions into the ARGoS plugin system */
REGISTER_LOOP_FUNCTIONS(CForaging, "foraging");
