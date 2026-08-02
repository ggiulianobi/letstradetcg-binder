/* Converte HEIC/HEIF pra JPEG quando necessário, e comprime qualquer
   imagem redimensionando o lado maior pra ~2200px (mantendo zoom bom)
   com qualidade JPEG 82% — reduz bastante o tamanho do arquivo. */
async function processImage(file){
  let workFile = file;

  const isHeic = /heic|heif/i.test(file.type) || /\.(heic|heif)$/i.test(file.name);
  if(isHeic && window.heic2any){
    try{
      workFile = await window.heic2any({ blob: file, toType: "image/jpeg", quality: 0.9 });
    }catch(e){
      console.error("Falha ao converter HEIC:", e);
      throw new Error("Não foi possível converter essa foto HEIC. Tente exportar como JPEG.");
    }
  }

  const bitmap = await createImageBitmap(workFile);
  const maxEdge = 2200;
  let { width, height } = bitmap;
  if(Math.max(width, height) > maxEdge){
    const ratio = maxEdge / Math.max(width, height);
    width = Math.round(width * ratio);
    height = Math.round(height * ratio);
  }

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  canvas.getContext("2d").drawImage(bitmap, 0, 0, width, height);

  return await new Promise(resolve => canvas.toBlob(resolve, "image/jpeg", 0.82));
}
